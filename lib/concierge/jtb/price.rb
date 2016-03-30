module JTB
  # +JTB::Price+
  #
  # This class belongs to the process of getting the price of a stay
  # for a JTB property. It gets responses by +JTB::API+
  #
  # Usage
  #
  #   price = JTB::Price.new(credentials)
  #   price.quote(params)
  #   # => #<Result error=nil value=Quotation>
  class Price
    include Concierge::JSON

    ENDPOINT       = 'GA_HotelAvail_v2013'
    OPERATION_NAME = :gby010
    CURRENCY       = 'JPY'
    CACHE_PREFIX   = 'jtb.rate_plan'

    attr_reader :credentials, :rate_plan

    def initialize(credentials)
      @credentials = credentials
    end

    # quotes the price with JTB by leveraging the +response_parser+.
    # This method will always return a +Quotation+ instance.
    def quote(params)
      result = best_rate_plan(params)
      if result.success?
        quotation = build_quotation(params, result.value)
        Result.new(quotation)
      else
        result
      end
    end

    # gets best rate plan by JTB API. This method caches response to avoid the same request to JTB API
    # because rate plan uses for +quote+ and +JTB::Booking#book+ methods
    def best_rate_plan(params)
      cache_key      = params.to_h.to_s
      cache_duration = 10 * 60 # ten minutes

      result = with_cache(cache_key, freshness: cache_duration) do
        message = builder.quote_price(params)
        remote_call(message)
      end

      if result.success?
        response_parser.parse_rate_plan(result.value, params)
      else
        result
      end
    end

    private

    def build_quotation(params, rate_plan)
      quotation_params = params.to_h.merge(total: rate_plan.total, available: rate_plan.available, currency: CURRENCY)
      Quotation.new(quotation_params)
    end

    def builder
      XMLBuilder.new(credentials)
    end

    def remote_call(message)
      caller.call(OPERATION_NAME, message: message.to_xml)
    end

    def response_parser
      @response_parser ||= ResponseParser.new
    end

    def caller
      @caller ||= API::Support::SOAPClient.new(options)
    end

    def options
      endpoint = [credentials.url, ENDPOINT].join('/')
      {
        wsdl:                 endpoint + '?wsdl',
        env_namespace:        :soapenv,
        namespace_identifier: 'jtb',
        endpoint:             endpoint
      }
    end

    def with_cache(key, freshness: Concierge::Cache::DEFAULT_TTL)
      payload = cache.fetch(key, freshness: freshness) { yield }
      if payload.success?
        # uses +to_json+ because value can be response Hash or cached String
        json_decode(payload.value.to_json)
      else
        payload
      end
    end

    def cache
      @_cache ||= Concierge::Cache.new(namespace: CACHE_PREFIX)
    end

  end
end