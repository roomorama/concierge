module SAW
  module Mappers
    # +SAW::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object.
    # Object initialization includes mapping of property attributes, rates,
    # amenitites, images, units.
    class RoomoramaProperty
      CANCELLATION_POLICY = 'moderate'

      # Bulds Roomorama::Property object
      #
      # Example
      #
      #   roomorama_property = SAW::Mappers::RoomoramaProperty.build(
      #     property,
      #     detailed_property,
      #   )
      #   => Roomorama::Property object
      #
      # Returns [Roomorama::Property] Roomorama property
      def self.build(basic_property, detailed_property)
        property = Roomorama::Property.new(basic_property.internal_id.to_s)
        property.type = basic_property.type
        property.title = basic_property.title
        property.lat = basic_property.lat
        property.lng = basic_property.lon
        property.currency = basic_property.currency_code
        property.country_code = basic_property.country_code
        property.nightly_rate = basic_property.nightly_rate
        property.weekly_rate = basic_property.weekly_rate
        property.monthly_rate = basic_property.monthly_rate
        property.multi_unit! if basic_property.multi_unit?

        property.description = description_with_additional_amenities(
          detailed_property.description,
          detailed_property.not_supported_amenities
        )
        property.city = detailed_property.city
        property.neighborhood = detailed_property.neighborhood
        property.postal_code = detailed_property.postal_code
        property.address = detailed_property.address
        property.amenities = detailed_property.amenities

        property.minimum_stay = 1
        property.default_to_available = true
        property.cancellation_policy = CANCELLATION_POLICY
        property.instant_booking!

        set_units!(property, basic_property, detailed_property)
        set_images!(property, detailed_property.images)
        property
      end

      private

      def self.set_images!(property, images)
        images.each { |image| property.add_image(image) }
      end

      def self.set_units!(property, basic_property, detailed_property)
        units = SAW::Mappers::RoomoramaUnitSet.build(
          basic_property,
          detailed_property
        )

        units.each { |unit| property.add_unit(unit) }
      end

      def self.description_with_additional_amenities(description, amenities)
        text = description.to_s.strip
        text_amenities = formatted_additional_amenities(amenities)

        description_parts = [text, text_amenities].reject(&:empty?)

        if description_parts.any?
          description_parts.join('. ')
        else
          nil
        end
      end

      def self.formatted_additional_amenities(amenities)
        if amenities.any?
          text = 'Additional amenities: '
          text += amenities.join(', ')
        else
          ""
        end
      end
    end
  end
end
