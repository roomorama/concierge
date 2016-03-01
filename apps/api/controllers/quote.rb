require_relative "./params/quote"

module API::Controllers

  module Quote

    def self.included(base)
      base.class_eval do
        include API::Action
        include API::Support::JSONEncode

        params API::Controllers::Params::Quote

        expose :quotation
      end
    end

    def call(params)
      if params.valid?
        @quotation = quote_price(params)
        self.body = API::Views::Quote.render(exposures)
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
