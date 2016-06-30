module SAW
  module Mappers
    # +SAW::Mappers::BeddingConfiguration+
    #
    # This class is responsible for building a
    # +SAW::Entities::BeddingConfiguration+ object from the hash which was
    # fetched from the SAW API.
    class BeddingConfiguration
      class << self
        # Builds a bedding configuration object
        #
        # Arguments:
        #
        #   * +bedding_config+ [Concierge::SafeAccessHash] attributes
        #
        # Returns [SAW::Entities::BeddingConfiguration]
        def build(bedding_config)
          number_of_single_beds = 0
          number_of_double_beds = 0

          beds = bedding_config.get("bed_type")
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
      end
    end
  end
end
