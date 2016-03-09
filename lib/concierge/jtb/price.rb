module JTB
  class Price

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def quote(params)
      result = api.quote_price(params)
      if result.success?
        response_parser.parse_quote result.value.body
      else
        result
      end
    end

    private

    def response_parser
      ResponseParser.new
    end

    def api
      @api ||= JTB::API.new(credentials)
    end

  end
end