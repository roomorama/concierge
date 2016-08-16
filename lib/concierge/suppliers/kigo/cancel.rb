module Kigo

  # +Kigo::Cancel+
  #
  # This class wraps the logic belonging to the process of cancellation bookings
  # for a Kigo property. Such operation is performed by calling the +cancelReservation+
  # API call offered by Kigo's API.
  #
  # A +request_handler+ can be injected to this class to provide different behavior.
  # The goal is for the same logic to be applied interchangeable between
  # Kigo's new API and Kigo's Legacy API, since both are active and handle different sets of
  # properties at the moment. The default request and response handlers deal with Kigo's
  # new API - i.e., custom behavior is necessary for Kigo's Legacy API.
  #
  # Usage
  #
  #   cancel = Kigo::Cancel.new(credentials)
  #   cancel.call(params)
  #   # => #<Result error=nil value="123456">
  class Cancel
    include Concierge::JSON

    API_METHOD = "cancelReservation"

    attr_reader :credentials, :request_handler

    def initialize(credentials, request_handler: nil)
      @credentials     = credentials
      @request_handler = request_handler || default_request_handler
    end

    def call(params)
      endpoint = request_handler.endpoint_for(API_METHOD)
      body     = json_encode(RES_ID: params[:reference_number].to_i)
      result   = http.post(endpoint, body, { "Content-Type" => "application/json" })

      if result.success?
        response_parser(params).parse_cancellation(result.value.body)
      else
        result
      end
    end

    private

    def default_request_handler
      @request_handler ||= Kigo::Request.new(credentials)
    end

    def response_parser(params)
      Kigo::ResponseParser.new(params)
    end

    def http
      request_handler.http_client
    end
  end

end
