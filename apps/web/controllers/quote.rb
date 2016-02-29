require_relative "./params/quote"

module Web::Controllers

  module Quote

    def self.included(base)
      base.class_eval do
        include Web::Action
        include Web::Support::JSONEncode

        params Web::Controllers::Params::Quote

        expose :quotation
      end
    end

    def call(params)
      if params.valid?
        @quotation = quote_price(params)
        self.body = Web::Views::Quote.render(exposures)
      else
        status 422, invalid_request(params.error_messages)
      end
    end

    private

    def invalid_request(errors)
      response = { status: "error" }.merge!(errors: errors)
      json_encode(response)
    end
  end

end
