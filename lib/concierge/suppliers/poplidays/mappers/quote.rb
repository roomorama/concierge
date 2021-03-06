module Poplidays
  module Mappers
    # +Poplidays::Mappers::Quote+
    #
    # This class is responsible for building a +Roomorama::Quotation+ object
    # from data getting from Poplidays API.
    class Quote

      # currency information is not included in the response, but prices are
      # always quoted in EUR.
      CURRENCY = 'EUR'

      # Maps Poplidays API responses to +Roomorama::Quotation+
      # Arguments
      #
      #   * +params+ Roomorama quotation webhook params
      #   * +mandatory_services+ [Float] mandatory services price
      #   * +quote+ [Result] result which contains response from Poplidays booking/easy method
      #                      in "EVALUATION" mode
      # Returns a +Result+ wrapping +Roomorama::Quotation+
      def build(params, mandatory_services, quote)
        quotation = ::Quotation.new(
          property_id:         params[:property_id],
          check_in:            params[:check_in].to_s,
          check_out:           params[:check_out].to_s,
          guests:              params[:guests],
          available:           available?(quote),
        )
        if quotation.available
          return unexpected_quote_error unless quote.value['value']

          quotation.currency = CURRENCY
          quotation.total = calc_total(mandatory_services, quote)
        end
        Result.new(quotation)
      end

      private

      def available?(quote)
        quote.success?
      end

      def calc_total(mandaroty_services, quote)
        (quote.value['value'].to_f + mandaroty_services.to_f).round(2)
      end

      def unexpected_quote_error
        desc = "Unexpected quote: empty response result['value'] from API"
        Result.error(:unexpected_quote, desc)
      end
    end
  end
end
