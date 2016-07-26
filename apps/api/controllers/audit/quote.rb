require_relative "../quote"

module API::Controllers::Audit

  # API::Controllers::Audit::Quote
  #
  # Performs booking quotations for properties from Audit.
  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      Audit::Client.new.quote(params)
    end

    def supplier_name
      Audit::Client::SUPPLIER_NAME
    end
  end
end

