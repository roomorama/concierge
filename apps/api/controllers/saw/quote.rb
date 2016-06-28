require_relative "../quote"

module API::Controllers::SAW
  # API::Controllers::SAW::Quote
  #
  # Performs booking quotations for properties from SAW.
  class Quote
    include API::Controllers::Quote
    
    params API::Controllers::Params::MultiUnitQuote

    # Make price (property rate) request 
    #
    # Usage
    #
    #   It returns a Quotation object in both success and fail cases:
    #   
    #   API::Controllers::SAW::Quote.quote_price(selected_params)
    #   => Quotation(..)
    def quote_price(params)
      credentials = Concierge::Credentials.for("SAW")
      SAW::Client.new(credentials).quote(params)
    end
  end
end
