module SAW
  module Mappers
    class PropertyRate
      class << self
        def build(hash)
          property_rate = Entities::PropertyRate.new(
            units: build_units(hash),
            currency: parse_currency(hash)
          )
        end

        private

        def parse_currency(hash)
          hash.fetch("response")
              .fetch("property")
              .fetch("currency_code")
        end
      
        def build_units(hash)
          units = hash.fetch("response")
                      .fetch("property")
                      .fetch("apartments")
                      .fetch("accommodation_type")
                      .fetch("property_accommodation")

          to_array(units).map do |unit_hash|
            Entities::UnitRate.new(
              id: parse_id(unit_hash),
              price: parse_price(unit_hash)
            )
          end
        end

        def parse_id(hash)
          hash.fetch("@id").to_i
        end

        def parse_price(hash)
          hash.fetch("price_detail")
              .fetch("net")
              .fetch("total_price")
              .fetch("price")
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
