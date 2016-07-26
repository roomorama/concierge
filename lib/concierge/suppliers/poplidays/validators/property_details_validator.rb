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
      attr_reader :details

      # details is a hash representation of response from Poplidays lodging method
      def initialize(details)
        @details = details
      end

      def valid?
        !on_request_only? && price_enabled?
      end

      private

      def on_request_only?
        details['requestOnly']
      end

      def price_enabled?
        details['priceEnabled']
      end
    end
  end
end