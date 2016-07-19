module Kigo
  #  +Kigo::Booking+
  #
  # This class responsible for creating booking through Kigo's API.
  class Booking
    include Concierge::JSON

    API_METHOD = 'createConfirmedReservation'

    attr_reader :credentials, :request_handler, :response_parser

    def initialize(credentials, request_handler: nil, response_parser: nil)
      @credentials     = credentials
      @request_handler = request_handler || default_request_handler
      @response_parser = response_parser || default_response_parser
    end


    # Always returns a wrapped +Reservation+ object.
    # If an error happens in any step in the process of getting a response back from
    # Kigo, a generic error message is sent back to the caller, and the failure
    # is logged
    #
    # example:
    #   booking = Kigo::Booking.new(credentials)
    #   booking.book(params)
    #
    #   # => #<Result error=nil value=#<Reservation code='123'>>
    def book(params)
      reservation_details = request_handler.build_reservation_details(params)

      return reservation_details unless reservation_details.success?

      endpoint = request_handler.endpoint_for(API_METHOD)
      result   = http.post(endpoint, json_encode(reservation_details.value))

      if result.success?
        response_parser.parse_reservation(params, result.value.body)
      else
        result
      end
    end

    private


    def default_request_handler
      @request_handler ||= Kigo::Request.new(credentials)
    end

    def default_response_parser
      @response_parser ||= Kigo::ResponseParser.new
    end

    def http
      request_handler.http_client
    end
  end
end