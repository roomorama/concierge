module Kigo

  # +Kigo::LegacyRequest+
  #
  # Builds upon +Kigo::Request+ in order to implement a proper request to Kigo's
  # legacy API.
  #
  # Usage
  #
  #   builder = Kigo::Request.new(credentials)
  #   request = Kigo::LegacyRequest.new(credentials, builder)
  #   request.build_compute_pricing(params)
  #   # => #<Result error=nil value={..., "RES_CREATE" => ... }>
  class LegacyRequest
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
      @http_client ||= Concierge::HTTPClient.new(base_uri, client_options)
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


    # Kigo Legacy API requires all parameters required by Kigo's new
    # Channels API, with the addition of two parameters:
    #
    # +RES_N_BABIES+: the number of babies.
    def build_reservation_details(params)
      result = builder.build_reservation_details(params)

      if result.success?
        Result.new(result.value.merge!("RES_N_BABIES" => 0))
      else
        result
      end
    end

    private

    def client_options
      {
        basic_auth: {
          username: credentials.username,
          password: credentials.password
        },
        headers:    { "Content-Type" => "application/json" }
      }
    end
  end
end