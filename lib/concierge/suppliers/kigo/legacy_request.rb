module Kigo

  # +Kigo::LegacyRequest+
  #
  # Builds upon +Kigo::Request+ in order to implement a proper request to Kigo's
  # legacy API.
  #
  # Usage
  #
  #   request = Kigo::LegacyRequest.new(credentials)
  #   request.build_compute_pricing(params)
  #   # => #<Result error=nil value={..., "RES_CREATE" => ... }>
  class LegacyRequest
    BASE_URI = "https://app.kigo.net"

    attr_reader :credentials, :options

    def initialize(credentials, options = {})
      @credentials = credentials
      @options     = options.merge(auth_options)
    end

    def base_uri
      BASE_URI
    end

    # Kigo Legacy API uses HTTP Basic Authentication to authenticate with
    # their servers. A username and password combination is required.
    def http_client
      @http_client ||= Concierge::HTTPClient.new(base_uri, options).tap do |client|
        client.retry(409, 8)  # There are about 300 hosts, 8 retries will resolve 256 collisions
      end
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

    def auth_options
      {
        basic_auth: {
          username: credentials.username,
          password: credentials.password
        }
      }
    end

    def builder
      @builder ||= Kigo::Request.new(credentials)
    end
  end
end
