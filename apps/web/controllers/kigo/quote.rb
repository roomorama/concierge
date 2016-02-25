module Web::Kigo
  class Quote
    include Web::Action

    expose :quotation

    # These classes are obviously not going to be defined here. Their definitions
    # are here for ease of reference.
    class PriceRequest
      def initialize(params)
      end

      def valid?
        parameters_given? && valid_stay_dates?
      end

      def errors
        # ...
      end
    end

    class Quotation
      # successful meaning if the API call to the partner was successful
      def successful?
      end

      def total
      end

      def fee
      end

       # ...
    end

    # Input: PriceRequest
    # Output: Quotation
    def Kigo::Client.new(credentials).quote(request)
    end

    def call(params)
      price_request = PriceRequest.new(params)

      if price_request.valid?
        @quotation = ::Kigo::Client.new(credentials).quote(price_request)
        unless @quotation.successful?
          status "503", error(@quotation.errors)
        end
      else
        status "422", errors(price_request.errors)
      end
    end
  end
end
