module SAW
  module Mappers
    # +SAW::Mappers::Country+
    #
    # This class is responsible for building a +SAW::Entities::Country+ 
    # object from the hash which was fetched from the SAW API.
    class Country
      class << self
        # Builds a country
        #
        # Arguments:
        #
        #   * +hash+ [Concierge::SafeAccessHash] country parameters
        #
        # Returns [SAW::Entities::Country]
        def build(hash)
          Entities::Country.new(
            id: hash.get("@id"),
            name: hash.get("country_name")
          )
        end
      end
    end
  end
end
