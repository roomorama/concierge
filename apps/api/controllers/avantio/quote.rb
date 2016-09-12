require_relative "../quote"

module API::Controllers::Avantio
  # API::Controllers::Avantio::Quote
  #
  # Performs booking quotations for properties from Avantio.
  class Quote
    include API::Controllers::Quote

    params API::Controllers::Params::Quote

    def quote_price(params)
      credentials = Concierge::Credentials.for(supplier_name)
      Avantio::Client.new(credentials).quote(params)
    end

    def supplier_name
      Avantio::Client::SUPPLIER_NAME
    end
  end
end
