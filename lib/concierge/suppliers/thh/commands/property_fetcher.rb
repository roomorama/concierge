module THH
  module Commands
    #  +THH::Commands::PropertyFetcher+
    #
    # This class is responsible for fetching a property details
    # from THH API and parsing the response to +Concierge::SafeAccessHash+.
    #
    # Usage
    #
    #   result = THH::Commands::PropertyFetcher.new(credentials).call(property_id)
    #   if result.success?
    #     result.value # SafeAccessHash with details
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates SafeAccessHash.
    class PropertyFetcher < BaseFetcher
      LANGUAGE = 'en'
      PROPERTY_KEY = 'response.property'

      def call(property_id)
        result = api_call(params(property_id))
        return result unless result.success?

        response = result.value
        property = response.get(PROPERTY_KEY)
        return unrecognised_response_error(PROPERTY_KEY, property_id) unless property

        Result.new(Concierge::SafeAccessHash.new(property))
      end

      protected

      def action
        'data'
      end

      private

      def unrecognised_response_error(field, property_id)
        Result.error(:unrecognised_response, "Property response for id `#{property_id}` does not contain `#{field}` field")
      end

      def params(property_id)
        {
          'rate'   => 'd', # rate per day
          'date'   => '3', # YYYY-MM-DD format
          'booked' => '2', # booked dates as periods
          'text'   => '2', # Clean Text without HTML
          'curr'   => THH::Commands::PropertiesFetcher::CURRENCY,
          'lang'   => LANGUAGE,
          'id'     => property_id
        }
      end
    end
  end
end
