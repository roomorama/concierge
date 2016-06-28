module Ciirus
  module Mappers
    class PropertyAvailable
      class << self
        # Maps hash representation of Ciirus API IsPropertyAvailable response
        # to bool
        def build(hash)
          hash.get('is_property_available_response.is_property_available_result')
        end
      end
    end
  end
end
