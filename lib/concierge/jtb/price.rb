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
    CURRENCY = 'JPY'
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # quotes the price with JTB by leveraging the +response_parser+.
    # This method will always return a +Quotation+ instance.
    def quote(params)
      result = api.quote_price(params)
      if result.success?
        response_parser.parse_quote result.value, params
      else
        result
      end
    end

    private

    def response_parser
      @response_parser ||= ResponseParser.new
    end

    def api
      @api ||= JTB::API.new(credentials)
    end

  end
end