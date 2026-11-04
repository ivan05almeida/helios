require "faraday"

module FaradayConnection
  def conn(base_url)
    @conn ||= Faraday.new(url: base_url) do |builder|
      builder.headers["User-Agent"] = "Helios/1.0 (contact: ivan05filho@gmail.com)"
      builder.response :json
      builder.response :raise_error
      builder.response :logger, Rails.logger, headers: true, bodies: false

      yield(builder) if block_given?
    end
  end
end
