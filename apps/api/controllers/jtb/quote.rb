require_relative "../quote"
require_relative "../params/multi_unit_quote"

module API::Controllers::JTB

  # API::Controllers::JTB::Quote
  #
  # Performs booking quotations for properties from JTB.
  class Quote
    include API::Controllers::Quote

    params API::Controllers::Params::MultiUnitQuote

    def quote_price(params)
      credentials = Concierge::Credentials.for("jtb")
      rescue_with_generic_quotation JTB::Client::SUPPLIER_NAME do
        JTB::Client.new(credentials).quote(params)
      end
    end

  end
end
