require_relative './quote_params'

module Web::Controllers::Jtb
  class Quote
    include Web::Action

    params QuoteParams
    expose :quotation

    def call(params)
      if params.valid?
        @quotation = client.quote(params)
        unless @quotation.successful?
          halt 503, @quotation.errors
        end
      else
        halt 422, params.errors
      end
    end

    private

    def client
      #Jtb::Client.new
    end
  end
end
