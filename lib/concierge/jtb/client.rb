module Jtb
  class Client

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def quote(params)
      response = api.quote_price(params)
      result = Jtb::Price.new(params).quote(response)

      if result.success?
        result.value
      else
        Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
      end
    end

    private

    def api
      @api ||= Jtb::Api.new(credentials)
    end

  end
end