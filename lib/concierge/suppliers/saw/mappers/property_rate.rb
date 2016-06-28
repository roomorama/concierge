module SAW
  module Mappers
    class PropertyRate
      class << self
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

          to_array(units).map do |unit_hash|
            safe_hash = Concierge::SafeAccessHash.new(unit_hash)

            Entities::UnitRate.new(
              id: parse_id(safe_hash),
              price: parse_price(safe_hash)
            )
          end
        end

        def parse_id(hash)
          hash.get("@id").to_i
        end

        def parse_price(hash)
          hash.get("price_detail.net.total_price.price")
        end
    
        def to_array(something)
          if something.is_a? Hash
            [something]
          else
            Array(something)
          end
        end
      end
    end
  end
end
