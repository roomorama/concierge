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

  end
end
