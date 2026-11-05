require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [ :method, :uri ]
  }
end

RSpec.configure do |config|
  config.after(:each, :vcr) do
    WebMock.reset!
  end
end
