require_relative "../quote"

module API::Controllers::Ciirus
  # API::Controllers::Ciirus::Quote
  #
  # Performs booking quotations for properties from Ciirus.
  class Quote
    include API::Controllers::Quote

    # Make price (property rate) request
    #
    # Usage
    #
    #   It returns a Quotation object in both success and fail cases:
    #
    #   API::Controllers::Ciirus::Quote.quote_price(selected_params)
    #   => Quotation(..)
    def quote_price(params)
      credentials = Concierge::Credentials.for("Ciirus")
      Ciirus::Client.new(credentials).quote(params)
    end
  end
end
