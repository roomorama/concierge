module THH
  module Commands
    class PropertiesFetcher < BaseFetcher
      # Currency response contains prices in.
      # Currently THH has a bug with security deposit amount,
      # it is always in THB. If you want to change this value
      # check the behavior of security deposit
      CURRENCY = 'THB'
      LANGUAGE = 'en'
      TIMEOUT = 60
      PROPERTIES_KEY = 'response.property'

      def call
        result = api_call(params)
        return result unless result.success?

        response = result.value

        properties = response.get(PROPERTIES_KEY)
        return unrecognised_response_error unless properties

        Result.new(Array(properties))
      end

      protected

      def action
        'data_all'
      end

      def timeout
        TIMEOUT
      end

      private

      def unrecognised_response_error
        Result.error(:unrecognised_response, "Response does not contain `#{PROPERTIES_KEY}` field")
      end

      def params
        {
          'rate'   => 'd', # rate per day
          'date'   => '3', # YYYY-MM-DD format
          'booked' => '2', # booked dates as periods
          'text'   => '2', # Clean Text without HTML
          'curr'   => CURRENCY,
          'lang'   => LANGUAGE
        }
      end
    end
  end
end
