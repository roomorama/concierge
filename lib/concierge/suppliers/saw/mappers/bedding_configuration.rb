module SAW
  module Mappers
    class BeddingConfiguration
      class << self
        def build(bedding_config)
          number_of_single_beds = 0
          number_of_double_beds = 0

          beds = to_array(bedding_config.fetch("bed_type"))
          beds.each do |bed|
            single_count, double_count = detect_beds(bed)
            number_of_double_beds = number_of_double_beds + double_count
            number_of_single_beds = number_of_single_beds + single_count
          end

          SAW::Entities::BeddingConfiguration.new(
            number_of_double_beds: number_of_double_beds,
            number_of_single_beds: number_of_single_beds
          )
        end

        private
        def detect_beds(bed_configuraton)
          string = bed_configuraton.fetch("bed_type_name")

          double_count = string.scan(/double/i).size
          single_count = string.scan(/single/i).size + 2 * string.scan(/twin/i).size

          [single_count, double_count]
        end

        def to_array(something)
          if something.is_a? Hash
            [something]
          else
            Array(something)
          end
        end
      end
    end
  end
end
