require "faraday"

module FaradayConnection
  RETRYABLE_ERRORS = [
    Faraday::TimeoutError,
    Faraday::ConnectionFailed,
    Errno::ECONNRESET
  ].freeze

  def conn(base_url)
    Faraday.new(url: base_url) do |builder|
      builder.headers["User-Agent"] = "Helios/1.0 (contact: ivan05filho@gmail.com)"

      builder.request :retry, {
        max:                 3,
        interval:            0.5,
        interval_randomness: 0.5,
        backoff_factor:      2,
        exceptions:          RETRYABLE_ERRORS
      }

      builder.response :raise_error
      builder.response :json
      builder.response :logger, Rails.logger, headers: true, bodies: false

      yield(builder) if block_given?
    end
  end
end
