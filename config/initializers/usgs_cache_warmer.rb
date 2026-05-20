# USGS MRDS cache warmer.
#
# The USGS Mineral Resources Data System endpoint we hit on /mines is slow
# (10-22s per commodity, measured). Without a warm cache, the very first
# request for each commodity pays that full cost. This initializer
# pre-fetches every commodity in UsgsMinesService::COMMODITIES on boot, on
# a background thread, so by the time the first user hits /mines all 7
# results are already sitting in Rails.cache.
#
# Guarded so it only fires when actually serving HTTP traffic:
#   * not in the test environment (tests stub the service / forbid network)
#   * only when Rails::Server is defined, i.e. `bin/rails server` / `bin/dev`
#     and not during `rake`, `rails console`, `rails runner`, `db:prepare`,
#     asset precompile, etc.
#
# Errors inside the warmer thread are swallowed and logged - a network
# blip on boot must never crash the server. The next request will still
# work, it just won't be served from cache.

return if Rails.env.test?
return unless defined?(Rails::Server)

Rails.application.config.after_initialize do
  Thread.new do
    Thread.current.name = "usgs-cache-warmer"

    started = Time.current
    Rails.logger.info("[UsgsCacheWarmer] starting background warm of #{UsgsMinesService::COMMODITIES.size} commodities")

    begin
      results = UsgsMinesService.warm_cache!
      elapsed = (Time.current - started).round(1)
      Rails.logger.info("[UsgsCacheWarmer] warmed in #{elapsed}s: #{results.inspect}")
    rescue StandardError => e
      Rails.logger.warn("[UsgsCacheWarmer] aborted: #{e.class}: #{e.message}")
    end
  end
end
