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
    ENDPOINT       = 'GA_HotelAvail_v2013'
    OPERATION_NAME = :gby010
    CURRENCY       = 'JPY'

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

    def best_rate_plan(params)
      message = builder.quote_price(params)
      result  = remote_call(message)
      if result.success?
        response_parser.parse_rate_plan result.value
      else
        result
      end
    end

    private

    def build_quotation(params, rate_plan)
      quotation_params = params.merge(total: rate_plan.total, available: rate_plan.available, currency: CURRENCY)
      Quotation.new(quotation_params)
    end

    # === todo: move to reusable class ======
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
    #  ========================================

  end
end