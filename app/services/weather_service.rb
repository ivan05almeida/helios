class WeatherService
  CACHE_TTL = 30.minutes

  ADAPTERS = [
    OpenMeteoAdapter
  ].index_by(&:adapter_name).freeze

  class OutOfRangeCoordinatesError < StandardError; end
  class AdapterNofFoundError < StandardError; end

  def initialize(adapter)
    @adapter = adapter
  end

  def forecast(lat:, long:, force: false)
    validate_coords!(lat: lat.to_f, long: long.to_f)

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

  private

  def validate_coords!(lat:, long:)
    return if lat.between?(-90, 90) && long.between?(-180, 180)

    raise OutOfRangeCoordinatesError, "Coordinates are outside valid ranges."
  end

  class << self
    def for(adapter_name)
        adapter_class = adapter_lookup!(adapter_name || OpenMeteoAdapter.adapter_name)

        new(adapter_class)
    end

    def adapter_lookup!(adapter_name)
        ADAPTERS.fetch(adapter_name.to_sym) do
            raise AdapterNofFoundError, "Unknown weather adapter: #{adapter_name}. Available options are: #{ADAPTERS.keys.to_sentence}"
        end
    end
  end
end
