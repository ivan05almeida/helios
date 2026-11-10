source "https://rubygems.org"

gem "rails", "~> 8.1.4"

gem "bootsnap", require: false
gem "faraday", "~> 2.15"
gem "faraday-retry", "~> 2.4"
gem "importmap-rails"
gem "jbuilder"
gem "kamal", require: false
gem "propshaft"
gem "puma", ">= 5.0"
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"
gem "sqlite3", ">= 2.1"
gem "stimulus-rails"
gem "stoplight", "~> 6.0"
gem "tailwindcss-rails", "~> 4.7"
gem "thruster", require: false
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "rspec-rails", "~> 8.1"
  gem "simplecov", "~> 1.3"
  gem "vcr", "~> 6.4"
  gem "webmock", "~> 3.34"
end
