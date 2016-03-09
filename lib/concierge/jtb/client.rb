module JTB
  class Client

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def quote(params)
      result = JTB::Price.new(credentials).quote(params)

      if result.success?
        result.value
      else
        Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
      end
    end

  end
end