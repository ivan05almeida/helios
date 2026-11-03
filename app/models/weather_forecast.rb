CurrentWeather = Data.define(
  :datetime,
  :temperature,
  :apparent_temperature,
  :humidity,
  :precipitation,
  :wind_speed,
  :condition,
  :is_day
)

HourlyForecast = Data.define(
  :datetime,
  :temperature,
  :apparent_temperature,
  :humidity,
  :precipitation_probability,
  :condition,
  :is_day
)

# Sub-object for daily forecast items
DailyForecast = Data.define(
  :date,
  :max_temperature,
  :min_temperature,
  :precipitation,
  :precipitation_probability,
  :wind_speed,
  :condition
)

WeatherForecast = Data.define(
#   :zip_code,
  :current,
  :hourly,
  :daily
)
