module SAW
  module Mappers
    # +SAW::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object.
    # Object initialization includes mapping of property attributes, rates,
    # amenitites, availabilities, images, units.
    class RoomoramaProperty
      # Bulds Roomorama::Property object
      #
      # Example
      #
      #   roomorama_property = SAW::Mappers::RoomoramaProperty.build(
      #     property,
      #     detailed_property,
      #     availability_calendar
      #   )
      #   => Roomorama::Property object
      #
      # Returns [Roomorama::Property] Roomorama property
      def self.build(basic_property, detailed_property, availabilities)
        property = Roomorama::Property.new(basic_property.internal_id)
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
        
        property.description = detailed_property.description
        property.city = detailed_property.city
        property.neighborhood = detailed_property.neighborhood
        property.address = detailed_property.address
        property.amenities = detailed_property.amenities
        
        property.default_to_available = true
        property.instant_booking!

        set_availabilities!(property, availabilities)
        set_images!(property, detailed_property.images)
        set_units!(property, basic_property, detailed_property)
        # not_supported_amenities: detailed_property.not_supported_amenities
        property
      end

      private
      def self.set_availabilities!(property, availabilities)
        availabilities.each do |date, status|
          property.update_calendar(date => status)
        end
      end

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
    end
  end
end
