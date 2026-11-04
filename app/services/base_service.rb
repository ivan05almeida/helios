require "faraday"
require "json"

class BaseService
  class ClientError < StandardError; end
  class ServerError < StandardError; end

  HELIOS_USER_AGENT = "Helios/1.0 (contact: ivan05filho@gmail.com)"

  private

  def conn
    Faraday.new(url: self.class::BASE_URL) do |builder|
      builder.headers["User-Agent"] = HELIOS_USER_AGENT
      builder.response :json
      builder.response :raise_error
      builder.response :logger

      yield(builder) if block_given?
    end
  end

  def handle_response(response)
    case response.status
    when 200..299
      JSON.parse(response.body, symbolize_names: true)
    when 400..499
      raise ClientError, "Client Error #{response.status}: #{response.body}"
    when 500..599
      raise ServerError, "Server Error #{response.status}: #{response.body}"
    else
      raise Faraday::Error, "Unexpected status #{response.status}: #{response.body}"
    end
  end
end
