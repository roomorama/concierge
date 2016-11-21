module Poplidays
  module Validators
    # +Poplidays::Validators::PropertyDetailsValidator+
    #
    # This class responsible for property details validation.
    # cases when details invalid:
    #
    #   * property is on request only
    #   * property price is only available through call center
    #
    class PropertyDetailsValidator
      ON_REQUEST_MESSAGE = 'Property is not instant bookable'
      PRICE_ENABLED_MESSAGE = 'Price for the property is only available through call center'
      INVALID_PERSON_MAX_MESSAGE = 'Max guests is 0 or nil'

      attr_reader :details, :error

      # details is a hash representation of response from Poplidays lodging method
      def initialize(details)
        @details = details
        @error = nil
      end

      def valid?
        instant_bookable? && price_enabled? && valid_max_guests?
      end

      private

      def instant_bookable?
        result = details['requestOnly']
        @error = ON_REQUEST_MESSAGE if result
        !result
      end

      def price_enabled?
        result = details['priceEnabled']
        @error = PRICE_ENABLED_MESSAGE unless result
        result
      end

      def valid_max_guests?
        result = (details['personMax'].to_i > 0)
        @error = INVALID_PERSON_MAX_MESSAGE unless result
        result
      end
    end
  end
end