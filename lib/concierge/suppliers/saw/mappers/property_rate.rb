module SAW
  module Mappers
    # +SAW::Mappers::PropertyRate+
    #
    # This class is responsible for building a +SAW::Entities::PropertyRate+ 
    # object from the hash which was fetched from the SAW API.
    class PropertyRate
      class << self
        # Builds a property rate object
        #
        # Arguments:
        #
        #   * +hash+ [Concierge::SafeAccessHash] property rate object
        #                                        attributes
        #
        # Returns [SAW::Entities::PropertyRate]
        def build(hash)
          Entities::PropertyRate.new(
            units: build_units(hash),
            currency: parse_currency(hash)
          )
        end

        private

        def parse_currency(hash)
          hash.get("response.property.currency_code")
        end
      
        def build_units(hash)
          units = hash.get(
            "response.property.apartments.accommodation_type.property_accommodation"
          )

          Array(units).map do |unit_hash|
            safe_hash = Concierge::SafeAccessHash.new(unit_hash)

            Entities::UnitRate.new(
              id: parse_id(safe_hash),
              price: parse_price(safe_hash),
              available: parse_availability(safe_hash)
            )
          end
        end

        def parse_id(hash)
          hash.get("@id").to_i
        end

        def parse_price(hash)
          hash.get("price_detail.net.total_price.price")
        end

        def parse_availability(hash)
          flag = hash.get("flag_bookable_property_accommodation")

          flag == "Y" ? true : false
        end
      end
    end
  end
end
