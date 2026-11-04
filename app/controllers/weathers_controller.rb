class WeathersController < ApplicationController
  def new; end

  def show
    service = WeatherService.for(params[:provider])

    result = service.forecast(
      lat:  params[:latitude],
      long: params[:longitude],
      force: ActiveModel::Type::Boolean.new.cast(params[:force])
    )

    @location_name     = params[:name]
    @zipcode           = params[:zipcode]
    @location_timezone = ActiveSupport::TimeZone[params[:location_timezone]] || ActiveSupport::TimeZone["UTC"]
    @timezone          = ActiveSupport::TimeZone[params[:timezone]] || ActiveSupport::TimeZone["UTC"]
    @forecast          = result[:forecast]
    @cached            = result[:cached]
    @units             = @forecast.units
  end
end
