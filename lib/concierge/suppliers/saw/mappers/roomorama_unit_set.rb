module SAW
  module Mappers
    # +SAW::Mappers::RoomoramaUnitSet+
    #
    # This class is responsible for building an array of units for the
    # property.
    #
    # Array of units includes +Roomorama::Unit+ objects
    class RoomoramaUnitSet
      # Builds an array of property units
      #
      # Arguments:
      #
      #   * +basic_property+ [SAW::Entities::BasicProperty]
      #   * +detailed_property+ [SAW::Entities::DetailedProperty]
      #
      # +detailed_property+ includes two attributes-hashes:
      #
      #   * +bed_configurations+ [Concierge::SafeAccessHash]
      #   * +property_accommodations+ [Concierge::SafeAccessHash]
      #
      # Returns [Array<Roomorama::Unit] array of property units
      def self.build(basic_property, detailed_property, unit_rates)
        bed_configurations = fetch_bed_configurations(detailed_property.bed_configurations)
        property_accommodations = fetch_property_accommodations(detailed_property.property_accommodations)

        property_accommodations.map do |hash|
          units = Array(safe_hash(hash).get("property_accommodation"))
          units.map do |unit_hash|
            unit_rate = find_unit_rate(unit_hash["@id"], unit_rates)
            build_unit(unit_hash, basic_property, detailed_property, bed_configurations, unit_rate)
          end
        end.flatten
      end

      private
      def self.build_unit(unit_hash, basic_property, detailed_property, bed_configurations, unit_rate)
        unit = safe_hash(unit_hash)

        u = Roomorama::Unit.new(unit.get("@id"))
        u.title = unit.get("property_accommodation_name")
        u.description = basic_property.description
        u.number_of_units = 1
        u.number_of_bedrooms = parse_number_of_bedrooms(unit)
        u.amenities = detailed_property.amenities

        bed_configuration = find_bed_types(bed_configurations, u.identifier)

        if bed_configuration
          u.number_of_double_beds = bed_configuration.number_of_double_beds
          u.number_of_single_beds = bed_configuration.number_of_single_beds
        end

        if unit_rate
          u.nightly_rate = unit_rate.nightly_rate
          u.weekly_rate = unit_rate.weekly_rate
          u.monthly_rate = unit_rate.monthly_rate
          u.max_guests = unit_rate.max_guests
        else
          u.nightly_rate = basic_property.nightly_rate
          u.weekly_rate = basic_property.weekly_rate
          u.monthly_rate = basic_property.monthly_rate

          if bed_configuration
            u.max_guests = bed_configuration.max_guests
          end
        end
        u
      end

      def self.find_unit_rate(unit_id, unit_rates)
        return nil unless unit_rates

        unit_rates.units.find { |u| u.id == unit_id }
      end

      def self.fetch_bed_configurations(bed_configurations)
        if bed_configurations
          Array(bed_configurations.get("property_accommodation")).map do |hash|
            safe_hash(hash)
          end
        else
          []
        end
      end

      def self.fetch_property_accommodations(property_accommodations)
        if property_accommodations
          Array(property_accommodations.get("accommodation_type"))
        else
          []
        end
      end

      def self.find_bed_types(configurations, unit_id)
        configuration = configurations.detect do |config|
          config.get("@id") == unit_id
        end

        if configuration
          SAW::Mappers::BeddingConfiguration.build(
            safe_hash(configuration).get("bed_types")
          )
        else
          nil
        end
      end

      def self.safe_hash(hash)
        Concierge::SafeAccessHash.new(hash)
      end

      def self.parse_number_of_bedrooms(unit_hash)
        name = unit_hash.get("property_accommodation_name")

        # most likely there is a bedrooms count in the apartment name:
        # 5 Bedroom - 3 Bathroom, 1-Bedroom, 2 Bedrooms, etc
        bedrooms_count = name[/\d/]
        return bedrooms_count.to_i if bedrooms_count

        # in other cases return 1:
        # Studio, Standard apartment, etc
        return 1
      end
    end
  end
end
