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
    # Usage
    #
    #   It returns a Quotation object in both success and fail cases:
    #
    #   API::Controllers::RentalsUnited::Quote.quote_price(selected_params)
    #   => Quotation(..)
    def quote_price(params)
      credentials = Concierge::Credentials.for(supplier_name)
      RentalsUnited::Client.new(credentials).quote(params)
    end

    def supplier_name
      RentalsUnited::Client::SUPPLIER_NAME
    end
  end
end
