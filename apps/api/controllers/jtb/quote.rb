require_relative "../quote"
require_relative "../params/multi_unit_quote"

module API::Controllers::JTB

  # API::Controllers::JTB::Quote
  #
  # Performs booking quotations for properties from JTB.
  class Quote
    include API::Controllers::Quote

    MAXIMUM_STAY_LENGTH = 14 # days

    params API::Controllers::Params::MultiUnitQuote

    def quote_price(params)
      return unavailable_quotation if params.stay_length > MAXIMUM_STAY_LENGTH
      credentials = Concierge::Credentials.for("jtb")
      JTB::Client.new(credentials).quote(params)
    end

    private

    def unavailable_quotation
      Quotation.new(errors: { quote: "Maximum length of stay must be less than #{MAXIMUM_STAY_LENGTH} nights." })
    end

  end
end
