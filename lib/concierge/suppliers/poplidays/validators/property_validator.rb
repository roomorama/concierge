module Poplidays
  module Validators
    # +Poplidays::Validators::PropertyValidator+
    #
    # This class responsible for properties validation.
    # cases when property invalid:
    #
    #   * property is on request only
    #
    class PropertyValidator
      attr_reader :property

      # property is a hash representation of response from Poplidays lodgings method
      def initialize(property)
        @property = property
      end

      def valid?
        !on_request_only?
      end

      private

      def on_request_only?
        property['requestOnly']
      end
    end
  end
end