require "rexml/document"

# USGS Mineral Resources Data System (MRDS) — public, no-auth REST endpoints
# hosted by the U.S. Geological Survey at https://mrdata.usgs.gov.
#
# We use two endpoints:
#   * search-by-name.php  -> XML list of mines whose name contains the query
#   * to-json.php         -> GeoJSON Feature with the full record for one site
#
# Docs (per-endpoint pages): https://mrdata.usgs.gov/catalog/api.php
#
# Service methods all return plain Ruby (Array<Hash> / Hash / nil) so the
# controller and views don't need to know anything about HTTP, XML, or
# GeoJSON shapes.
class UsgsMinesService
  BASE = "https://mrdata.usgs.gov".freeze

  # How long to keep a successful search result in Rails.cache before we
  # re-hit USGS. The MRDS catalog is updated on a multi-month cadence, so
  # an hour is generous to us and invisible to users.
  CACHE_TTL = 1.hour

  # Commodities the controller rotates through on /mines, and the same
  # list the boot-time warmer pre-populates into Rails.cache. Lives on the
  # service (not the controller) so there's one source of truth shared by
  # the request path and the warmer.
  COMMODITIES = %w[gold copper silver iron diamond zinc lead].freeze

  class << self
    # Returns an Array of mine summary hashes for sites whose name matches
    # the query (e.g. "copper", "gold"). Returns [] on any failure.
    #
    # Each hash has: :dep_id, :name, :state, :latitude, :longitude,
    #                :status, :dev_stat
    #
    # Results are memoized in Rails.cache for CACHE_TTL. The USGS endpoint
    # routinely takes 10-22 seconds to respond, so caching turns the second
    # (and every subsequent) page load for the same commodity into an
    # in-process memory read.
    #
    # Caching policy:
    #   * HTTP failure (body is nil) -> NOT cached, so the next request can
    #     retry instead of being locked into an empty banner for the TTL.
    #   * HTTP success, any record count (including 0) -> cached. An empty
    #     result for e.g. "zinc" is a legitimate API answer ("no mines
    #     literally named zinc"), not a failure, and we don't want to
    #     re-pay the 2-3 second network round trip every time `sample`
    #     picks it.
    def search_by_name(query, limit: 10)
      query = query.to_s.strip
      return [] if query.empty?

      cache_key = "usgs_mines/search/#{query.downcase}/limit-#{limit}/v1"
      cached    = Rails.cache.read(cache_key)
      if cached
        Rails.logger.info("[UsgsMinesService] cache HIT  #{cache_key}")
        return cached
      end
      Rails.logger.info("[UsgsMinesService] cache MISS #{cache_key}")

      url  = "#{BASE}/mrds/search-by-name.php?q=#{URI.encode_www_form_component(query)}"
      body = ApiClient.fetch(url)
      return [] if body.nil?

      records = parse_search_results(body, limit: limit)
      Rails.cache.write(cache_key, records, expires_in: CACHE_TTL)
      records
    end

    # Fetches the full GeoJSON record for a single mine by its dep_id.
    # Returns a flattened summary hash, or nil on any failure.
    def find(dep_id)
      return nil if dep_id.blank?

      url  = "#{BASE}/to-json.php?db=mrds&id=dep_id&labno=#{URI.encode_www_form_component(dep_id.to_s)}"
      json = ApiClient.fetch_json(url)
      return nil unless json.is_a?(Hash)

      flatten_geojson_record(json)
    end

    # Pre-fetches search_by_name for every commodity in COMMODITIES so the
    # first request for /mines reads from Rails.cache instead of waiting
    # 10-22 seconds on USGS. Called from the boot-time initializer
    # (config/initializers/usgs_cache_warmer.rb) on a background thread so
    # server startup is not blocked.
    #
    # Each commodity is fetched sequentially - we deliberately do NOT
    # parallelize, both to be polite to a public government API and to
    # avoid all 7 timeouts piling up at once if USGS is down.
    #
    # Returns a Hash of {commodity => record_count} for logging.
    def warm_cache!(limit: 10)
      COMMODITIES.each_with_object({}) do |commodity, results|
        records = search_by_name(commodity, limit: limit)
        results[commodity] = records.size
      rescue StandardError => e
        Rails.logger.warn("[UsgsMinesService] warm_cache! #{commodity} crashed: #{e.class}: #{e.message}")
        results[commodity] = :error
      end
    end

    private

    # The search-by-name endpoint returns XML that looks like:
    #
    #   <search db="mrds" text="copper" rel="matches">
    #     <match dep_id="..." name="..." status="..." latitude="..."
    #            longitude="..." state="..." dev_stat="..."/>
    #     ...
    #   </search>
    def parse_search_results(xml_body, limit:)
      doc     = REXML::Document.new(xml_body)
      matches = doc.elements.to_a("//match")
      matches.first(limit).map do |el|
        {
          dep_id:    el.attributes["dep_id"],
          name:      el.attributes["name"],
          status:    el.attributes["status"],
          dev_stat:  el.attributes["dev_stat"],
          state:     el.attributes["state"],
          latitude:  el.attributes["latitude"]&.to_f,
          longitude: el.attributes["longitude"]&.to_f
        }
      end
    rescue REXML::ParseException => e
      Rails.logger.warn("[UsgsMinesService] XML parse failed: #{e.message}")
      []
    end

    # GeoJSON Feature -> a flat hash the view can render easily.
    def flatten_geojson_record(feature)
      props   = feature["properties"] || {}
      coords  = (feature.dig("geometry", "coordinates") || [])
      dep     = props["deposits"]    || {}
      name    = props["name"]        || {}
      loc     = props["location"]    || {}
      commod  = props["commodity"]   || {}
      land    = props["land_status"] || {}
      phys    = props["physiography"] || {}

      {
        dep_id:      dep["dep_id"],
        name:        name["name"],
        commodity:   commod["commod"],
        commodity_group: commod["commod_group"],
        commodity_type:  commod["commod_tp"],
        dev_status:  dep["dev_st"],
        operation:   dep["oper_tp"],
        method:      dep["min_meth"],
        country:     loc["country"],
        state:       loc["state_prov"],
        county:      loc["county"],
        latitude:    coords[1],
        longitude:   coords[0],
        land_status: land["land_st"],
        physiography_province: phys["phys_prov"]
      }
    end
  end
end
