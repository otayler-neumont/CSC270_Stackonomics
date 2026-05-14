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

  class << self
    # Returns an Array of mine summary hashes for sites whose name matches
    # the query (e.g. "copper", "gold"). Returns [] on any failure.
    #
    # Each hash has: :dep_id, :name, :state, :latitude, :longitude,
    #                :status, :dev_stat
    def search_by_name(query, limit: 10)
      query = query.to_s.strip
      return [] if query.empty?

      url  = "#{BASE}/mrds/search-by-name.php?q=#{URI.encode_www_form_component(query)}"
      body = ApiClient.fetch(url)
      return [] if body.nil?

      parse_search_results(body, limit: limit)
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
