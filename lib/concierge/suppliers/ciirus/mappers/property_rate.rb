module Ciirus
  module Mappers
    class PropertyRate
      class << self
        # Maps hash representation of Ciirus API IsPropertyAvailable response
        # to bool
        def build(hash)
          Entities::PropertyRate.new(
            hash.get('from_date'),
            hash.get('to_date'),
            hash.get('min_nights_stay'),
            hash.get('daily_rate')
          )
        end
      end
    end
  end
end