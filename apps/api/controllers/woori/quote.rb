require_relative "../quote"
require_relative "../params/multi_unit_quote"

module API::Controllers::Woori
  # API::Controllers::Woori::Quote
  #
  # Performs booking quotations for properties from Woori.
  class Quote
    include API::Controllers::Quote
    
    params API::Controllers::Params::MultiUnitQuote

    # Make price (property rate) request 
    #
    # Usage
    #
    #   It returns a Quotation object in both success and fail cases:
    #   
    #   API::Controllers::Woori::Quote.quote_price(selected_params)
    #   => Quotation(..)
    def quote_price(params)
      credentials = Concierge::Credentials.for(supplier_name)
      Woori::Client.new(credentials).quote(params)
    end
    
    def supplier_name
      Woori::Client::SUPPLIER_NAME
    end
  end
end
