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
      def self.build(basic_property, detailed_property)
        bed_configurations = Array(detailed_property.bed_configurations)
        property_accommodations = fetch_property_accommodations(detailed_property.property_accommodations)
          
        property_accommodations.map do |hash|
          units = Array(safe_hash(hash).get("property_accommodation"))
          units.map do |unit_hash|
            build_unit(unit_hash, basic_property, bed_configurations)
          end
        end.flatten
      end

      private
      def self.build_unit(unit_hash, basic_property, bed_configurations)
        unit = safe_hash(unit_hash)

        u = Roomorama::Unit.new(unit.get("@id"))
        u.title = unit.get("property_accommodation_name")
        u.description = basic_property.description
        u.nightly_rate = basic_property.nightly_rate
        u.weekly_rate = basic_property.weekly_rate
        u.monthly_rate = basic_property.monthly_rate
        u.number_of_units = 1

        bed_configuration = find_bed_types(bed_configurations, unit.get("@id"))

        if bed_configuration
          u.number_of_double_beds = bed_configuration.number_of_double_beds
          u.number_of_single_beds = bed_configuration.number_of_single_beds
          u.max_guests = bed_configuration.max_guests
        end
        u
      end

      def self.fetch_property_accommodations(property_accommodations)
        if property_accommodations
          Array(property_accommodations.get("accommodation_type"))
        else
          []
        end
      end

      def self.find_bed_types(configurations, current_id)
        configuration = configurations.detect do |config|
          config.get("@id") == current_id
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
    end
  end
end
