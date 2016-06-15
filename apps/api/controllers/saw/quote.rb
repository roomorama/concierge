require_relative "../quote"

module API::Controllers::SAW
  class Quote
    include API::Controllers::Quote

    # returns Quotation object (for both success and fail cases)
    def quote_price(params)
      credentials = Concierge::Credentials.for("SAW")
      SAW::Client.new(credentials).quote(params)
    end
  end
end
