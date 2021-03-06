require_relative "../quote"

module API::Controllers::Kigo

  # API::Controllers::Kigo::Quote
  #
  # Performs booking quotations for properties from Kigo (currently known as
  # Kigo/Real Page).
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      credentials = Concierge::Credentials.for("Kigo")
      Kigo::Client.new(credentials).quote(params)
    end

    def supplier_name
      Kigo::Client::SUPPLIER_NAME
    end

  end
end

