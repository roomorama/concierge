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
          Array(beds).each do |bed|
            safe_bed_hash = Concierge::SafeAccessHash.new(bed)

            single_count, double_count = detect_beds(safe_bed_hash)
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
          string = bed_configuraton.get("bed_type_name")

          double_count = string.scan(/double/i).size
          twin_count   = string.scan(/twin/i).size
          bunk_count   = string.scan(/bunk/i).size
          sofa_count   = string.scan(/sofa/i).size
          single_count = string.scan(/single/i).size + sofa_count + 2 * twin_count + 2 * bunk_count

          [single_count, double_count]
        end
      end
    end
  end
end
