require_relative "../quote"

module Web::Controllers::AtLeisure

  class Quote
    include Web::Controllers::Quote

    def quote_price(params)
      # AtLeisure::Client.new.quote(params)
      Quotation.new(params)
    end

  end
end
