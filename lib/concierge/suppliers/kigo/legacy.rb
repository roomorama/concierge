module Kigo

  # +Kigo::Legacy+
  #
  # This class is a client for the Kigo Legacy API. While it holds a lot of
  # similarity with the new Kigo Channels API, some properties can only
  # be queried against the old endpoints.
  #
  # Usage
  #
  #   quotation = Kigo::Legacy.new(credentials).quote(stay_params)
  #   if quotation.sucessful?
  #     # ...
  #   end
  #
  # For more information on how to interact with Kigo Channels API and the Kigo
  # Legacy API, check the project Wiki.
  class Legacy

    # +Kigo::Legacy::Request+
    #
    # Builds upon +Kigo::Request+ in order to implement a proper request to Kigo's
    # legacy API.
    #
    # Usage
    #
    #   builder = Kigo::Request.new(credentials)
    #   request = Kigo::Legacy::Request(builder)
    #   request.build_compute_pricing(params)
    #   # => #<Result error=nil value={..., "RES_CREATE" => ... }>
    class Request
      BASE_URI = "https://app.kigo.net"

      attr_reader :credentials, :builder

      def initialize(credentials, builder)
        @credentials = credentials
        @builder     = builder
      end

      def base_uri
        BASE_URI
      end

      # Kigo Legacy API uses HTTP Basic Authentication to authenticate with
      # their servers. A username and password combination is required.
      def http_client
        @http_client ||= Concierge::HTTPClient.new(base_uri, basic_auth: {
          username: credentials.username,
          password: credentials.password
        })
      end

      def endpoint_for(api_method)
        ["/api/ra/v1/", api_method].join
      end

      # Kigo Legacy API requires all parameters required by Kigo's new
      # Channels API, with the addition of two parameters:
      #
      # +RES_CREATE+: the booking creation date.
      # +RES_N_BABIES+: the number of babies.
      def build_compute_pricing(params)
        result = builder.build_compute_pricing(params)

        if result.success?
          Result.new(result.value.merge!({
            "RES_CREATE"   => Date.today.to_s,
            "RES_N_BABIES" => 0
          }))
        else
          result
        end
      end

    end

    SUPPLIER_NAME = "Kigo Legacy"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Always returns a +Quotation+.
    # Uses an instance +Kigo::Legacy::Request+ to dictate parameters and endpoints.
    def quote(params)
      result = Kigo::Price.new(credentials, request_handler: request_handler).quote(params)

      if result.success?
        result.value
      else
        announce_error("quote", result)
        Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
      end
    end

    private

    def request_handler
      Request.new(credentials, Kigo::Request.new(credentials))
    end

    def announce_error(operation, result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   operation,
        supplier:    SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end

end
