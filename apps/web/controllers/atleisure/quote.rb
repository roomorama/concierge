require_relative "../params/quote"

module Web::Controllers::AtLeisure

  class Quote
    include Web::Action
    params Web::Controllers::Params::Quote

    expose :quotation

    def call(params)
      if params.valid?
        @quotation = Struct.new(:name, :errors).new("AtLeisure", params)
      else
        @quotation = Struct.new(:name, :errors).new("AtLeisure", params.error_messages)
      end
    end

  end
end
