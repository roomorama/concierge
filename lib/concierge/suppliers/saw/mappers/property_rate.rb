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
            id: hash.get("@id"),
            units: build_units(hash),
            currency: parse_currency(hash)
          )
        end

        private

        def parse_currency(hash)
          hash.get("currency_code")
        end

        def build_units(hash)
          units = hash.get(
            "apartments.accommodation_type.property_accommodation"
          )

          Array(units).map do |unit_hash|
            safe_hash = Concierge::SafeAccessHash.new(unit_hash)

            Entities::UnitRate.new(
              id: safe_hash.get("@id"),
              price: parse_price(safe_hash),
              available: parse_availability(safe_hash),
              max_guests: parse_max_guests(safe_hash)
            )
          end
        end

        def parse_price(hash)
          price = hash.get("price_detail.net.total_price.price")
          BigDecimal.new(price)
        end

        def parse_availability(hash)
          flag = hash.get("flag_bookable_property_accommodation")

          flag == "Y"
        end

        def parse_max_guests(hash)
          hash.get("maximum_guests").to_i
        end
      end
    end
  end
end
