module Kigo::Mappers
  class Beds
    SINGLE_BED_IDS = [4, 5, 14]
    DOUBLE_BED_IDS = [1, 2, 3]
    SOFA_BED_IDS   = [8, 9, 15]

    attr_reader :ids

    def initialize(ids)
      @ids = ids
    end

    def single_beds
      ids.select { |id| SINGLE_BED_IDS.include?(id)}
    end

    def double_beds
      ids.select { |id| DOUBLE_BED_IDS.include?(id)}
    end

    def sofa_beds
      ids.select { |id| SOFA_BED_IDS.include?(id)}
    end
  end
end