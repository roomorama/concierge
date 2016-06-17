module SAW
  # +SAW::Booking+
  #
  # This class is responsible for wrapping the logic related to making a
  # reservation to SAW, parsing the response, and building the +Reservation+
  # object with the data returned from their API.
  #
  # Usage
  #
  #   result = SAW::Booking.new(credentials).book(reservation_params)
  #   if result.success?
  #     process_reservation(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # The +book+ method returns a +Result+ object that, when successful,
  # encapsulates the resulting +Reservation+ object.
  class Booking
    attr_reader :credentials, :payload_builder, :response_parser

    def initialize(credentials, payload_builder: nil, response_parser: nil)
      @credentials = credentials
      @payload_builder = payload_builder || default_payload_builder
      @response_parser = response_parser || default_response_parser
    end

    # Calls the SAW API method usung the HTTP client.
    # Returns a +Result+ object.
    def book(params)
      payload = payload_builder.build_booking_request(params)
      result = http.post(endpoint_for(:propertybooking), payload, content_type)

      if result.success?
        result_hash = response_parser.to_hash(result.value.body)

        if valid_result?(result_hash)
          reservation = SAW::Mappers::Reservation.build(params, result_hash)
          
          Result.new(reservation)
        else
          error_result(result_hash)
        end
      else
        result
      end
    end

    private
    def default_payload_builder
      @payload_builder ||= SAW::PayloadBuilder.new(credentials)
    end

    def default_response_parser
      @response_parser ||= SAW::ResponseParser.new
    end

    def http
      @http_client ||= Concierge::HTTPClient.new(credentials.url)
    end
    
    def endpoint_for(method)
      SAW::Endpoint.endpoint_for(method)
    end

    def content_type
      { "Content-Type" => "application/xml" }
    end
    
    def valid_result?(hash)
      hash["response"]["errors"].nil?
    end

    def error_result(hash)
      error = hash.fetch("response")
                  .fetch("errors")
                  .fetch("error")

      code = error.fetch("code")
      data = error.fetch("description")

      Result.error(code, data)
    end
  end
end
