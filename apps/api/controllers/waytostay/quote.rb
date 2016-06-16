require_relative "../quote"

module API::Controllers::Waytostay

  # API::Controllers::Waytostay::Quote
  #
  # Performs booking quotations for properties from Waytostay.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      Waytostay::Client.new.quote(params)
    end
  end
end
