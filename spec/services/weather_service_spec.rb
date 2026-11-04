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

  describe "#forecast", :vcr do
    subject(:service) { described_class.for(:open_meteo) }

    context "with valid coordinates" do
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

      context "with external API errors" do
        subject(:service) { described_class.for(:open_meteo) }

        it "raises an error on connection timeout" do
            stub_request(:get, /api.open-meteo.com/)
            .to_timeout

            expect {
            service.forecast(lat: lat, long: long)
            }.to raise_error(Faraday::ConnectionFailed)
        end

        it "raises an error on 500 internal server error" do
            stub_request(:get, /api.open-meteo.com/)
            .to_return(status: 500, body: "Internal Server Error")

            expect {
            service.forecast(lat: lat, long: long)
            }.to raise_error(Faraday::ServerError)
        end

        it "raises an error on 429 too many requests" do
            stub_request(:get, /api.open-meteo.com/)
            .to_return(status: 429, body: "Too Many Requests")

            expect {
            service.forecast(lat: lat, long: long)
            }.to raise_error(Faraday::ClientError)
        end
      end

      describe "current weather" do
        subject(:current) { service.forecast(lat: lat, long: long)[:forecast].current }

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
        subject(:hourly) { service.forecast(lat: lat, long: long)[:forecast].hourly }

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
        subject(:daily) { service.forecast(lat: lat, long: long)[:forecast].daily }

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

    context "with invalid coordinates" do
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
  end
end
