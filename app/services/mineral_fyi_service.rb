# MineralFYI mineral encyclopedia — public, no-auth REST API hosted at
# https://mineralfyi.com. Returns clean JSON, paginated.
#
# Docs: https://mineralfyi.com/developers/
#
# We use two endpoints:
#   * GET /api/v1/minerals/        -> paginated list (lightweight cards)
#   * GET /api/v1/minerals/{slug}/ -> full detail (hardness, formula, etc.)
#
# Service methods return plain Ruby data structures (Hash / Array<Hash>)
# so views don't need to know about pagination wrappers or HTTP.
class MineralFyiService
  BASE = "https://mineralfyi.com/api/v1".freeze

  # The MineralFYI slug for each of our curated gem names. MineralFYI
  # uses mineralogical names, not jewelry-trade names — e.g. ruby and
  # sapphire are both varieties of corundum; aquamarine is a variety of
  # beryl. So the slug we look up is the parent (or variety) mineral.
  GEM_SLUGS = {
    "Diamond"    => "diamond",
    "Ruby"       => "corundum",       # red corundum colored by chromium
    "Sapphire"   => "corundum",       # corundum + iron/titanium
    "Emerald"    => "beryl-emerald",  # variety entry exists in the DB
    "Opal"       => "opal",
    "Amethyst"   => "quartz",         # purple quartz
    "Topaz"      => "topaz",
    "Aquamarine" => "beryl",          # blue-green variety of beryl
    "Tanzanite"  => "zoisite",        # blue-violet variety of zoisite
    "Garnet"     => "garnet-almandine",
    "Tourmaline" => "tourmaline",
    "Turquoise"  => "turquoise"
  }.freeze

  class << self
    # Returns a Hash with the full encyclopedia entry for the given slug,
    # or nil on any failure.
    def find(slug)
      slug = slug.to_s.strip
      return nil if slug.empty?

      url  = "#{BASE}/minerals/#{URI.encode_www_form_component(slug)}/"
      json = ApiClient.fetch_json(url)
      return nil unless json.is_a?(Hash)

      summarize_record(json)
    end

    # Convenience: look up one of our curated gem names and return its
    # live encyclopedia data.
    def find_for_gem(gem_name)
      slug = GEM_SLUGS[gem_name.to_s]
      return nil if slug.nil?

      find(slug)
    end

    # Returns an Array of lightweight mineral summary Hashes (name, slug,
    # formula, hardness, etc.) from the first page of the public list.
    # Returns [] on any failure.
    def list(limit: 12)
      json = ApiClient.fetch_json("#{BASE}/minerals/")
      return [] unless json.is_a?(Hash) && json["results"].is_a?(Array)

      json["results"].first(limit).map { |record| summarize_record(record) }
    end

    private

    # Trims the API record down to just the fields the views care about,
    # and normalizes nils / empty strings into something predictable.
    def summarize_record(record)
      {
        name:                  record["name"],
        slug:                  record["slug"],
        formula:               record["formula"],
        crystal_system:        record["crystal_system_name"] || record["crystal_system"],
        mineral_class:         record["mineral_class_name"] || record["mineral_class"],
        hardness:              presence(record["hardness"]),
        specific_gravity:      presence(record["specific_gravity"]),
        color:                 presence(record["color"]),
        luster:                presence(record["luster"]),
        streak:                presence(record["streak"]),
        cleavage:              presence(record["cleavage"]),
        fracture:              presence(record["fracture"]),
        transparency:          presence(record["transparency"]),
        crystal_habit:         presence(record["crystal_habit"]),
        description:           presence(record["description"]),
        wikidata_id:           presence(record["wikidata_id"]),
        source_url:            record["slug"] ? "https://mineralfyi.com/mineral/#{record["slug"]}/" : nil
      }
    end

    def presence(value)
      return nil if value.nil?

      str = value.to_s.strip
      str.empty? ? nil : str
    end
  end
end
