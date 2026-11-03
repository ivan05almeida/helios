class WeatherAdapter
    class_attribute :adapter_name

    class << self
        def forecast(lat:, long:)
            fail NotImplementedError
        end

        def builder
            fail NotImplementedError
        end
    end
end
