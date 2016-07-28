require_relative "../quote"

module API::Controllers::Poplidays

  # API::Controllers::Poplidays::Quote
  #
  # Performs booking quotations for properties from Poplidays.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      credentials = Concierge::Credentials.for(Poplidays::Client::SUPPLIER_NAME)
      Poplidays::Client.new(credentials).quote(params)
    end

    def supplier_name
      Poplidays::Client::SUPPLIER_NAME
    end

  end
end
