class OpenMeteoAdapter < WeatherAdapter
    self.adapter_name = :open_meteo

    class << self
        def forecast(lat:, long:)
            OpenMeteo::WeatherApiService.forecast(lat: lat, long: long)
        end

        def builder
            OpenMeteo::ForecastBuilder
        end
    end
end
