module Ciirus
  module Validators
    # +Ciirus::Validators::PropertyValidator+
    #
    # This class responsible for properties validation.
    # cases when property invalid:
    #
    #   * bad property type
    #   * unknown country
    #
    class PropertyValidator
      attr_reader :property

      def initialize(property)
        @property = property
      end

      def valid?
        valid_property_type? && valid_country?
      end

      private

      def valid_property_type?
        # Roomorama doesn't import hotels
        !(['Unspecified', 'Hotel'].include?(property.type))
      end

      def valid_country?
        country = country_converter.code_by_name(property.country)
        unless country.success?
          augment_context(country.error.data)
          false
        end
        true
      end

      def augment_context(message)
        context = Concierge::Context::MissingBasicData.new(
          error_message: message,
          attributes:    payload
        )

        Concierge.context.augment(context)
      end

      def country_converter
        @country_converter ||= Ciirus::CountryCodeConverter.new
      end
    end
  end
end
