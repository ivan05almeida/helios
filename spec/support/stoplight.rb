require 'stoplight'

RSpec.configure do |config|
  config.after(:each) do
    Stoplight.__stoplight__reset!
  end
end
