require_relative "../quote"

module API::Controllers::Waytostay

  # API::Controllers::Waytostay::Quote
  #
  # Performs booking quotations for properties from Waytostay.
  # If an error happens in any step in the process of getting a response back from
  # Waytostay, a generic error message is sent back to the caller, and the failure
  # is logged.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      rescue_with_generic_quotation Waytostay::Client::SUPPLIER_NAME do
        Waytostay::Client.new.quote(params)
      end
    end
  end
end
