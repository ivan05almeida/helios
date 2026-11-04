RSpec.configure do |config|
  config.around(:each, :caching) do |example|
    Rails.cache.clear
    example.run
    Rails.cache.clear
  end
end
