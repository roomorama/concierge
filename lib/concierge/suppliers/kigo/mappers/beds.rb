module Kigo::Mappers
  # +Kigo::Mappers::Beds+
  #
  # This class performs bed types matched by provided ids with reference data
  class Beds
    SINGLE_BED_IDS       = [4, 5, 9, 11]
    TWICE_SINGLE_BED_IDS = [13, 14]
    DOUBLE_BED_IDS       = [1, 2, 3]
    SOFA_BED_IDS         = [8, 9, 15]

    attr_reader :ids

    def initialize(ids)
      @ids = ids
    end

    def single_beds
      ids.select { |id| SINGLE_BED_IDS.include?(id) } + twice_single_beds
    end

    def double_beds
      ids.select { |id| DOUBLE_BED_IDS.include?(id) }
    end

    def sofa_beds
      ids.select { |id| SOFA_BED_IDS.include?(id) }
    end

    private

    # Kigo provides some bed types which match as 2 single beds (twin bed, trundle bed)
    def twice_single_beds
      ids.select { |id| TWICE_SINGLE_BED_IDS.include?(id) } * 2
    end
  end
end