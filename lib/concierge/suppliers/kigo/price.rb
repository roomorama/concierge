module Kigo

  # +Kigo::Price+
  #
  # This class wraps the logic belonging to the process of getting the price of a stay
  # for a Kigo property. Such calculation is performed by calling the +computePricing+
  # API call offered by Kigo's API.
  #
  # A +request_handler+ and a +response_parser+ can be injected to this class to provide
  # different behavior. The goal is for the same logic to be applied interchangeable between
  # Kigo's new API and Kigo's Legacy API, since both are active and handle different sets of
  # properties at the moment. The default request and response handlers deal with Kigo's
  # new API - i.e., custom behavior is necessary for Kigo's Legacy API.
  #
  # Usage
  #
  #   price = Kigo::Price.new(credentials)
  #   price.quote(params)
  #   # => #<Result error=nil value=Quotation>
  class Price
    include Concierge::JSON

    API_METHOD = "computePricing"

    attr_reader :credentials, :request_handler

    def initialize(credentials, request_handler: nil)
      @credentials     = credentials
      @request_handler = request_handler || default_request_handler
    end

    # quotes the price with Kigo by leveraging the +request_handler+ and +response_parser+
    # given on this object initialization. This method will always return a +Quotation+
    # instance.
    def quote(params)
      stay_details = request_handler.build_compute_pricing(params)
      return stay_details unless stay_details.success?

      endpoint = request_handler.endpoint_for(API_METHOD)
      result   = http.post(endpoint, json_encode(stay_details.value))

      if result.success?
        response_parser(params).compute_pricing(result.value.body)
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
