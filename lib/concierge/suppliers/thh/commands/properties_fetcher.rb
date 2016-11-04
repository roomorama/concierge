module THH
  module Commands
    #  +THH::Commands::PropertiesFetcher+
    #
    # This class is responsible for fetching a list of all properties
    # from THH API and parsing the response to Array of +Concierge::SafeAccessHash+.
    #
    # Usage
    #
    #   result = THH::Commands::PropertiesFetcher.new(credentials).call
    #   if result.success?
    #     result.value # Array
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates Array of SafeAccessHash.
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

        return unrecognised_response_error('response') unless response.to_h.key?('response')

        properties = response.get(PROPERTIES_KEY)

        Result.new(to_array(properties))
      end

      protected

      def action
        'data_all'
      end

      def timeout
        TIMEOUT
      end

      private

      def to_array(properties)
        Array(properties).map do |p|
          Concierge::SafeAccessHash.new(p)
        end
      end

      def unrecognised_response_error(field)
        Result.error(:unrecognised_response, "Response does not contain `#{field}` field")
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
