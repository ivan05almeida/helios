# frozen_string_literal: true

class OpenMeteo::WeatherApiService < BaseService
  class InvalidUnitError < StandardError; end

  BASE_URL = "https://api.open-meteo.com/v1/"
  FORECAST_HOURS = 24.freeze
  FORECAST_DEFAULT_DAYS = 7.freeze
  UNITS = %i[metric imperial].freeze

  def initialize(unit: :metric)
    raise InvalidUnitError, "Invalid Unit, supported values are #{UNITS.to_sentence}" unless UNITS.any?(unit)

    @unit = unit
  end

  def forecast(lat:, long:, forecast_days: FORECAST_DEFAULT_DAYS)
    conn.get('forecast', forecast_params(lat, long, forecast_days)).body
  end

  private

  def forecast_params(lat, long, forecast_days)
    {
      latitude: lat,
      longitude: long,
      current: current_weather_options,
      hourly: hourly_options,
      daily: daily_options,
      forecast_hours: FORECAST_HOURS,
      forecast_days: forecast_days,
      temperature_unit: temperature_unit,
      wind_speed_unit: wind_speed_unit,
      precipitation_unit: precipitation_unit,
    }.compact
  end

  def current_weather_options
    %w[temperature_2m relative_humidity_2m precipitation weather_code wind_speed_10m apparent_temperature is_day].join(',')
  end
  
  def hourly_options
    %w[temperature_2m relative_humidity_2m apparent_temperature precipitation_probability weather_code is_day].join(',')
  end

  def daily_options
    %w[temperature_2m_max temperature_2m_min precipitation_probability_max precipitation_sum weather_code wind_speed_10m_max].join(',')
  end
  
  def temperature_unit
    return if metric?
    
    :fahrenheit
  end

  def wind_speed_unit
    return if metric?
    
    :mph
  end

  def precipitation_unit
    return if metric?
    
    :inch
  end

  def metric?
    @unit == :metric
  end

  class << self
    def forecast(lat:, long:, unit: :metric, forecast_days: FORECAST_DEFAULT_DAYS)
      new(unit: unit).forecast(lat: lat, long: long, forecast_days: forecast_days)
    end
  end
end
