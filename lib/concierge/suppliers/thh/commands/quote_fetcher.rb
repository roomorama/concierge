module THH
  module Commands
    #  +THH::Commands::PropertyFetcher+
    #
    # This class is responsible for fetching availability information
    # (including price) from THH API and parsing the response
    # to +Concierge::SafeAccessHash+.
    #
    # Usage
    #
    #   result = THH::Commands::QuoteFetcher.new(credentials).call(params)
    #   if result.success?
    #     result.value # SafeAccessHash with availability info
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates SafeAccessHash.
    class QuoteFetcher < BaseFetcher
      ROOMORAMA_DATE_FORMAT = '%Y-%m-%d'
      THH_DATE_FORMAT = '%d/%m/%Y'
      REQUIRED_FIELDS = ['response.available', 'response.price']

      def call(params)
        result = api_call(params(params))
        return result unless result.success?

        response = Concierge::SafeAccessHash.new(result.value)
        result = validate_response(response, params)
        return result unless result.success?

        Result.new(response['response'])
      end

      protected

      def action
        'availability'
      end

      private

      def validate_response(response, params)
        REQUIRED_FIELDS.each do |field|
          unless response.get(field)
            return Result.error(:unrecognised_response, "Available response for params `#{params.to_h}` does not contain `#{field}` field")
          end
        end
        Result.new(true)
      end

      def params(params)
        {
          'arrival'   => convert_date(params[:check_in]),
          'departure' => convert_date(params[:check_out]),
          'curr'      => THH::Commands::PropertiesFetcher::CURRENCY,
          'id'        => params[:property_id]
        }
      end

      # Converts date string to THH expected format
      def convert_date(date)
        Date.strptime(date, ROOMORAMA_DATE_FORMAT).strftime(THH_DATE_FORMAT)
      end
    end
  end
end
