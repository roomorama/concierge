module Kigo::Mappers
  # +Kigo::Mappers::Beds+
  #
  # This class performs bed types matched by provided ids with reference data
  class Beds
    SINGLE_BED_IDS       = [4, 5, 9, 11]
    TWICE_SINGLE_BED_IDS = [13, 14]  # twin bed, trundle bed
    DOUBLE_BED_IDS       = [1, 2, 3]
    SOFA_BED_IDS         = [8, 9, 15]

    attr_reader :ids

    def initialize(ids)
      @ids = ids
    end

    def single_beds_size
      total(SINGLE_BED_IDS) + (total(TWICE_SINGLE_BED_IDS) * 2)
    end

    def double_beds_size
      total(DOUBLE_BED_IDS)
    end

    def sofa_beds_size
      total(SOFA_BED_IDS)
    end

    private

    def total(other_ids)
      ids.select { |id| other_ids.include?(id) }.size
    end
  end
end