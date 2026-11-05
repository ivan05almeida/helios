require "rails_helper"

RSpec.describe WeatherService do
  let(:lat)  { -23.56 }
  let(:long) { -46.63 }

  describe ".for" do
    it "returns a WeatherService instance for a valid adapter" do
      service = described_class.for(:open_meteo)
      expect(service).to be_a(described_class)
    end

    it "raises AdapterNotFoundError for an unknown adapter" do
      expect {
        described_class.for(:unknown_adapter)
      }.to raise_error(WeatherService::AdapterNofFoundError, /Unknown weather adapter/)
    end
  end

  describe "#forecast" do
    subject(:service) { described_class.for(:open_meteo) }

    context "with valid coordinates", :vcr do
      it "returns a WeatherForecast" do
        result = service.forecast(lat: lat, long: long)
        expect(result[:forecast]).to be_a(WeatherForecast)
      end

      it "returns cached: false on first call", :caching do
        result = service.forecast(lat: lat, long: long)
        expect(result[:cached]).to be false
      end

      it "returns cached: true on second call", :caching do
        service.forecast(lat: lat, long: long)
        result = service.forecast(lat: lat, long: long)
        expect(result[:cached]).to be true
      end

      it "returns cached: false when force: true", :caching do
        service.forecast(lat: lat, long: long)
        result = service.forecast(lat: lat, long: long, force: true)
        expect(result[:cached]).to be false
      end

      it "returns cached: false when force: true", :caching do
        VCR.use_cassette("WeatherService/_forecast/with_valid_coordinates/returns_cached_false_when_force_true", allow_playback_repeats: true) do
            service.forecast(lat: lat, long: long)

            travel 1.minute do
            result = service.forecast(lat: lat, long: long, force: true)
            expect(result[:cached]).to be false
            end
        end
      end

        it "returns cached: false after cache expires", :caching do
        VCR.use_cassette("WeatherService/_forecast/with_valid_coordinates/returns_cached_false_after_cache_expires", allow_playback_repeats: true) do
            service.forecast(lat: lat, long: long)

            travel 31.minutes do
            result = service.forecast(lat: lat, long: long)
            expect(result[:cached]).to be false
            end
        end
      end

      describe "current weather" do
        subject(:current) { service.forecast(lat: lat, long: long, force: true)[:forecast].current }

        it { is_expected.to be_a(CurrentWeather) }
        it { expect(current.temperature).to be_a(Numeric) }
        it { expect(current.apparent_temperature).to be_a(Numeric) }
        it { expect(current.humidity).to be_a(Numeric) }
        it { expect(current.precipitation).to be_a(Numeric) }
        it { expect(current.wind_speed).to be_a(Numeric) }
        it { expect(current.condition).to be_a(Numeric) }
        it { expect(current.datetime).to be_a(Time) }
        it { expect(current.is_day).to be(true).or be(false) }
      end

      describe "hourly forecast" do
        subject(:hourly) { service.forecast(lat: lat, long: long, force: true)[:forecast].hourly }

        it { is_expected.to be_an(Array) }
        it { expect(hourly.length).to eq(24) }
        it { expect(hourly).to all(be_a(HourlyForecast)) }

        describe "first entry" do
          subject(:entry) { hourly.first }

          it { expect(entry.temperature).to be_a(Numeric) }
          it { expect(entry.apparent_temperature).to be_a(Numeric) }
          it { expect(entry.humidity).to be_a(Numeric) }
          it { expect(entry.precipitation_probability).to be_a(Numeric) }
          it { expect(entry.condition).to be_a(Numeric) }
          it { expect(entry.datetime).to be_a(Time) }
          it { expect(entry.is_day).to be(true).or be(false) }
        end
      end

      describe "daily forecast" do
        subject(:daily) { service.forecast(lat: lat, long: long, force: true)[:forecast].daily }

        it { is_expected.to be_an(Array) }
        it { expect(daily.length).to eq(7) }
        it { expect(daily).to all(be_a(DailyForecast)) }

        describe "first entry" do
          subject(:entry) { daily.first }

          it { expect(entry.max_temperature).to be_a(Numeric) }
          it { expect(entry.min_temperature).to be_a(Numeric) }
          it { expect(entry.precipitation).to be_a(Numeric) }
          it { expect(entry.precipitation_probability).to be_a(Numeric) }
          it { expect(entry.wind_speed).to be_a(Numeric) }
          it { expect(entry.condition).to be_a(Numeric) }
          it { expect(entry.date).to be_a(Date) }
        end
      end
    end

    context "with invalid coordinates", :vcr do
      it "raises OutOfRangeCoordinatesError for latitude out of range" do
        expect {
          service.forecast(lat: 91, long: long)
        }.to raise_error(WeatherService::OutOfRangeCoordinatesError, /outside valid ranges/)
      end

      it "raises OutOfRangeCoordinatesError for longitude out of range" do
        expect {
          service.forecast(lat: lat, long: 181)
        }.to raise_error(WeatherService::OutOfRangeCoordinatesError, /outside valid ranges/)
      end

      it "raises OutOfRangeCoordinatesError for both out of range" do
        expect {
          service.forecast(lat: -91, long: -181)
        }.to raise_error(WeatherService::OutOfRangeCoordinatesError)
      end
    end

    context "with external API errors" do
      let(:valid_response) do
        {
          "current_units" => {
            "time" => "iso8601",
            "interval" => "seconds",
            "temperature_2m" => "°C",
            "relative_humidity_2m" => "%",
            "precipitation" => "mm",
            "weather_code" => "wmo code",
            "wind_speed_10m" => "km/h",
            "apparent_temperature" => "°C",
            "is_day" => ""
          },
          "current" => {
            "time"                => "2026-11-03T21:00",
            "temperature_2m"      => 22.1,
            "apparent_temperature"=> 24.0,
            "relative_humidity_2m"=> 85,
            "precipitation"       => 0.0,
            "wind_speed_10m"      => 3.2,
            "weather_code"        => 3,
            "is_day"              => 1
          },
          "hourly" => {
            "time"                     => Array.new(24) { |i| "2026-11-03T#{i.to_s.rjust(2, '0')}:00" },
            "temperature_2m"           => Array.new(24, 22.0),
            "relative_humidity_2m"     => Array.new(24, 85),
            "apparent_temperature"     => Array.new(24, 24.0),
            "precipitation_probability"=> Array.new(24, 0),
            "weather_code"             => Array.new(24, 3),
            "is_day"                   => Array.new(24, 1)
          },
          "daily" => {
            "time"                        => Array.new(7) { |i| (Date.today + i).to_s },
            "temperature_2m_max"          => Array.new(7, 30.0),
            "temperature_2m_min"          => Array.new(7, 18.0),
            "precipitation_probability_max"=> Array.new(7, 20),
            "precipitation_sum"           => Array.new(7, 0.0),
            "wind_speed_10m_max"          => Array.new(7, 15.0),
            "weather_code"                => Array.new(7, 3)
          }
        }
      end

      subject(:service) { described_class.for(:open_meteo) }

      before(:each) do
        Stoplight.__stoplight__reset!
      end


      it "raises ApiError on connection timeout" do
        stub_request(:get, /api.open-meteo.com/)
          .to_timeout.times(4)

        expect {
          service.forecast(lat: lat, long: long, force: true)
        }.to raise_error(OpenMeteo::ApiError, /Connection failed/)
      end

      it "raises ApiError on 500 internal server error" do
        stub_request(:get, /api.open-meteo.com/)
          .to_return(status: 500, body: "Internal Server Error")

        expect {
          service.forecast(lat: lat, long: long, force: true)
        }.to raise_error(OpenMeteo::ServerError, /Server error/)
      end

      it "raises ApiError on 429 too many requests" do
        stub_request(:get, /api.open-meteo.com/)
          .to_return(status: 429, body: "Too Many Requests")

        expect {
          service.forecast(lat: lat, long: long, force: true)
        }.to raise_error(OpenMeteo::ClientError, /Client error/)
      end

      it "opens the circuit after 3 consecutive failures" do
        stub_request(:get, /api.open-meteo.com/)
          .to_return(status: 500, body: "Internal Server Error")

        3.times do
          service.forecast(lat: lat, long: long, force: true) rescue nil
        end

        expect {
          service.forecast(lat: lat, long: long, force: true)
        }.to raise_error(OpenMeteo::ApiError, /currently unavailable/)

        expect(WebMock).to have_requested(:get, /api.open-meteo.com/).times(3)
      end

      it "recovers after cool off time" do
        stub_request(:get, /api.open-meteo.com/)
          .to_return(status: 500, body: "Internal Server Error")

        3.times do
          service.forecast(lat: lat, long: long, force: true) rescue nil
        end

        travel 61.seconds do
          stub_request(:get, /api.open-meteo.com/)
            .to_return(status: 200, body: valid_response.to_json,
                      headers: { "Content-Type" => "application/json" })

          expect {
            service.forecast(lat: lat, long: long, force: true)
          }.not_to raise_error
        end
      end
    end
  end
end
