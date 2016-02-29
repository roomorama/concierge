module Web::Controllers::AtLeisure

  class Quote
    include Web::Action

    expose :quotation

    def call(params)
      @quotation = Struct.new(:name).new("Kigo")
    end

  end
end
