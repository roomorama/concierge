module SAW
  module Mappers
    class RoomoramaUnitSet
      def self.build(basic_property, detailed_property)
        bed_configurations = fetch_bed_configurations(detailed_property.bed_configurations)
        property_accommodations = fetch_property_accommodations(detailed_property.property_accommodations)

        property_accommodations.map do |hash|
          id = hash["@id"]
          name = hash["accommodation_name"]

          units = to_array(hash.fetch("property_accommodation"))

          if units
            units.map do |unit|

              u = Roomorama::Unit.new(unit.fetch("@id"))
              u.title = unit.fetch("property_accommodation_name")
              u.description = basic_property.description
              u.nightly_rate = basic_property.nightly_rate
              u.weekly_rate = basic_property.weekly_rate
              u.monthly_rate = basic_property.monthly_rate
              u.number_of_units = 1

              bed_configuration = find_bed_types(bed_configurations, unit.fetch("@id"))

              if bed_configuration
                u.number_of_double_beds = bed_configuration.number_of_double_beds
                u.number_of_single_beds = bed_configuration.number_of_single_beds
                u.max_guests = bed_configuration.max_guests
              end
              u
            end
          else
            []
          end
        end.flatten
      end

      private
      def self.fetch_property_accommodations(property_accommodations)
        if property_accommodations
          to_array(property_accommodations["accommodation_type"])
        else
          []
        end
      end

      def self.fetch_bed_configurations(hash)
        configs = to_array(hash)
        
        configs ? configs : []
      end
        
      def self.find_bed_types(configurations, current_id)
        configuration = configurations.detect do |config|
          config["@id"] == current_id
        end

        if configuration
          SAW::Mappers::BeddingConfiguration.build(
            configuration.fetch("bed_types")
          )
        else
          nil
        end
      end
      
      def self.to_array(something)
        if something.is_a? Hash
          [something]
        else
          Array(something)
        end
      end
    end
  end
end
