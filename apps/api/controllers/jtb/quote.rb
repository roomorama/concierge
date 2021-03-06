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
      JTB::Client.new(credentials).quote(params)
    end

    def supplier_name
      JTB::Client::SUPPLIER_NAME
    end

  end
end
