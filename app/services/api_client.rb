require "net/http"
require "uri"
require "json"

# Tiny HTTP helper shared by Phase 2 API clients (UsgsMinesService,
# MineralFyiService). Wraps Net::HTTP with sane timeouts and a single
# failure mode: returns `nil` on any network/parse error so callers can
# decide how to degrade gracefully. Errors are logged for visibility.
class ApiClient
  OPEN_TIMEOUT = 4   # seconds to establish TCP/TLS
  READ_TIMEOUT = 8   # seconds to receive the full response body

  class << self
    # GET the URL and return the raw response body string, or nil on
    # any error (network, non-2xx, timeout).
    def fetch(url)
      uri = URI.parse(url)
      response = Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT
      ) do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        request["Accept"]     = "application/json, application/xml;q=0.9, */*;q=0.5"
        request["User-Agent"] = "Bedrock-CSC270/Phase2 (Rails #{Rails.version})"
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("[ApiClient] #{url} responded #{response.code}")
        return nil
      end

      response.body
    rescue StandardError => e
      Rails.logger.warn("[ApiClient] #{url} failed: #{e.class}: #{e.message}")
      nil
    end

    # GET the URL and parse the response body as JSON. Returns nil on
    # any HTTP or parse failure.
    def fetch_json(url)
      body = fetch(url)
      return nil if body.nil?

      JSON.parse(body)
    rescue JSON::ParserError => e
      Rails.logger.warn("[ApiClient] JSON parse failed for #{url}: #{e.message}")
      nil
    end
  end
end
