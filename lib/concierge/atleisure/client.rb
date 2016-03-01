module AtLeisure

  class Client
    def initialize(credentials = {})
    end

    def quote(params)
      Quotation.new(params.to_h)
    end
  end

end
