Stoplight.configure do |config|
  config.threshold = 3
  config.cool_off_time = 60
  config.notifiers = [ Stoplight::Notifier::Logger.new(Rails.logger) ]
  config.tracked_errors = [ Faraday::Error ]
end
