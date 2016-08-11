require_relative "../quote"

module API::Controllers::Ciirus
  # API::Controllers::Ciirus::Quote
  #
  # Performs booking quotations for properties from Ciirus.
  class Quote
    include API::Controllers::Quote

    params API::Controllers::Params::Quote

    def quote_price(params)
      credentials = Concierge::Credentials.for(supplier_name)
      Ciirus::Client.new(credentials).quote(params)
    end

    def supplier_name
      Ciirus::Client::SUPPLIER_NAME
    end
  end
end
