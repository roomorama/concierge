require_relative "../quote"

module API::Controllers::Jtb

  # API::Controllers::Jtb::Quote
  #
  # Performs booking quotations for properties from Jtb.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      credentials = Credentials.for("jtb")
      Jtb::Client.new(credentials).quote(params)
    end

  end
end
