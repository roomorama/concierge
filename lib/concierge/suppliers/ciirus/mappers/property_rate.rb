module Ciirus
  module Mappers
    class PropertyRate
      class << self
        # Maps hash representation of Ciirus API IsPropertyAvailable response
        # to bool
        def build(hash)
          Entities::PropertyRate.new(
            hash[:from_date],
            hash[:to_date],
            hash[:min_nights_stay].to_i,
            Float(hash[:daily_rate])
          )
        end
      end
    end
  end
end