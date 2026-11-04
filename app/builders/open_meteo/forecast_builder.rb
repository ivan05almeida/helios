class OpenMeteo::ForecastBuilder
    def initialize(response)
        @response = response
    end

    def build
        WeatherForecast.new(
            units: build_units,
            current: build_current,
            hourly: build_hourly,
            daily: build_daily
        )
    end

    private

    def build_units
        units_data = @response["current_units"]

        WeatherUnits.new(
            temperature: units_data["temperature_2m"],
            precipitation: units_data["precipitation"],
            wind_speed: units_data["wind_speed_10m"]
        )
    end


    def build_current
        current_data = @response["current"]
        time = current_data["time"]

        CurrentWeather.new(
            datetime: time ? Time.zone.parse(time) : nil,
            temperature: current_data["temperature_2m"].round(0),
            apparent_temperature: current_data["apparent_temperature"].round(0),
            precipitation: current_data["precipitation"],
            humidity: current_data["relative_humidity_2m"],
            wind_speed: current_data["wind_speed_10m"],
            condition: current_data["weather_code"],
            is_day: is_day?(current_data["is_day"])
        )
    end

    def build_hourly
        hourly_data = @response["hourly"]

        hourly_entries(hourly_data).map do |time, temp, hmd, a_temp, prec_prob, code, is_day|
            HourlyForecast.new(
                datetime: time ? Time.zone.parse(time) : nil,
                temperature: temp.round(0),
                humidity: hmd,
                apparent_temperature: a_temp.round(0),
                precipitation_probability: prec_prob,
                condition: code,
                is_day: is_day?(is_day)
            )
        end
    end

    def build_daily
        daily_data = @response["daily"]

        daily_entries(daily_data).map do |date, max_temp, min_temp, prec_prob, prec_sum, wind_max, code|
            DailyForecast.new(
                date: Date.parse(date),
                max_temperature: max_temp.round(0),
                min_temperature: min_temp.round(0),
                precipitation_probability: prec_prob,
                precipitation: prec_sum,
                wind_speed: wind_max,
                condition: code
            )
        end
    end

    def hourly_entries(data)
        hours  = data.fetch("time", [])
        temps  = data.fetch("temperature_2m", [])
        hmds = data.fetch("relative_humidity_2m", [])
        a_temps = data.fetch("apparent_temperature", [])
        prec_probs = data.fetch("precipitation_probability", [])
        codes  = data.fetch("weather_code", [])
        is_days = data.fetch("is_day", [])

        hours.zip(temps, hmds, a_temps, prec_probs, codes, is_days)
    end

    def daily_entries(data)
        dates  = data.fetch("time", [])
        max_temps  = data.fetch("temperature_2m_max", [])
        min_temps  = data.fetch("temperature_2m_min", [])
        prec_probs = data.fetch("precipitation_probability_max", [])
        prec_sums = data.fetch("precipitation_sum", [])
        wind_maxs = data.fetch("wind_speed_10m_max", [])
        codes  = data.fetch("weather_code", [])

        dates.zip(max_temps, min_temps, prec_probs, prec_sums, wind_maxs, codes)
    end

    def is_day?(value)
        value == 1
    end

    class << self
        def build(response)
            new(response).build
        end
    end
end
