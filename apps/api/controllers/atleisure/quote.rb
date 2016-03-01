require_relative "../quote"

module API::Controllers::AtLeisure

  class Quote
    include API::Controllers::Quote

    def quote_price(params)
      # AtLeisure::Client.new.quote(params)
      Quotation.new(params)
    end

  end
end
