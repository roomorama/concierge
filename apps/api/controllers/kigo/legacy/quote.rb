require_relative "../quote"

module API::Controllers::Kigo::Legacy

  # API::Controllers::Kigo::Legacy::Quote
  #
  # Performs booking quotations for properties from the Legacy Kigo
  # API.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      credentials = Credentials.for("KigoLegacy")
      Kigo::Legacy.new(credentials).quote(params)
    end

  end
end
