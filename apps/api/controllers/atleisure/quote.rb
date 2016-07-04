require_relative "../quote"

module API::Controllers::AtLeisure

  # API::Controllers::AtLeisure::Quote
  #
  # Performs booking quotations for properties from AtLeisure.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      credentials = Concierge::Credentials.for("AtLeisure")
      AtLeisure::Client.new(credentials).quote(params)
    end

    def supplier_name
      AtLeisure::Client::SUPPLIER_NAME
    end

  end
end
