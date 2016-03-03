require_relative "../quote"

module API::Controllers::AtLeisure

  # API::Controllers::AtLeisure::Quote
  #
  # Performs booking quotations for properties from AtLeisure.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      credentials = Credentials.for("AtLeisure")
      AtLeisure::Client.new(credentials).quote(params)
    end

  end
end
