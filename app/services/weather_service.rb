class WeatherService
  CACHE_TTL = 30.minutes

  def initialize(adapter)
    @adapter = adapter
  end

  def forecast(lat:, long:, force: false)
    lat_key = lat.to_f.round(2)
    lng_key = long.to_f.round(2)
    cache_key = "forecast:#{@adapter.adapter_name}:#{lat_key}:#{lng_key}"

    cached_hit = true

    forecast_data = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL, force: force) do
      cached_hit = false
      @adapter.forecast(lat: lat, long: long)
    end

    {
      forecast: @adapter.builder.build(forecast_data),
      cached: cached_hit
    }
  end
end