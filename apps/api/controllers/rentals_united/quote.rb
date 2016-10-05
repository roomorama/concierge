require_relative "../quote"

module API::Controllers::RentalsUnited
  # API::Controllers::RentalsUnited::Quote
  #
  # Performs booking quotations for properties from RentalsUnited.
  class Quote
    include API::Controllers::Quote

    params API::Controllers::Params::Quote

    # Make price (property rate) request
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def quote_price(params)
      credentials = Concierge::Credentials.for(supplier_name)
      RentalsUnited::Client.new(credentials).quote(params)
    end

    def supplier_name
      RentalsUnited::Client::SUPPLIER_NAME
    end
  end
end
