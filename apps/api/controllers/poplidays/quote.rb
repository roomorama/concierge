require_relative "../quote"

module API::Controllers::Poplidays

  # API::Controllers::Poplidays::Quote
  #
  # Performs booking quotations for properties from Poplidays.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      Poplidays::Client.new.quote(params)
    end

    def supplier_name
      Poplidays::Client::SUPPLIER_NAME
    end

  end
end
