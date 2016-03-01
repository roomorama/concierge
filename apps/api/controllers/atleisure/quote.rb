require_relative "../quote"

module API::Controllers::AtLeisure

  # API::Controllers::AtLeisure::Quote
  #
  # Performs booking quotations for properties from AtLeisure.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      AtLeisure::Client.new.quote(params)
    end

  end
end
