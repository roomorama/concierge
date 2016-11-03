module THH
  module Validators
    # +THH::Validators::PropertyValidator+
    #
    # This class responsible for properties validation.
    # cases when property invalid:
    #
    #   * no instant confirmation
    #
    class PropertyValidator

      attr_reader :property

      def initialize(property)
        @property = property
      end

      def valid?
        instant_confirmation?
      end

      private

      def instant_confirmation?
        property['instant_confirmation']
      end
    end
  end
end
