require_relative "../quote"

module API::Controllers::THH

  # API::Controllers::THH::Quote
  #
  # Performs booking quotations for properties from THH.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      credentials = Concierge::Credentials.for(THH::Client::SUPPLIER_NAME)
      THH::Client.new(credentials).quote(params)
    end

    def supplier_name
      THH::Client::SUPPLIER_NAME
    end
  end
end
