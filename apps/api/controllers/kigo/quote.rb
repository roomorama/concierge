require_relative "../quote"

module API::Controllers::Kigo

  # API::Controllers::Kigo::Quote
  #
  # Performs booking quotations for properties from Kigo (currently known as
  # Kigo/Real Page).
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      credentials = Credentials.for("Kigo")
      Kigo::Client.new(credentials).quote(params)
    end

  end
end
