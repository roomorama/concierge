module SAW
  module Mappers
    # +SAW::Mappers::UnitsPricing+
    #
    # This class is responsible for building a +SAW::Entities::UnitsPricing+
    # object from the hash which was fetched from the SAW API.
    class UnitsPricing
      class << self
        # Builds a property rate object
        #
        # Arguments:
        #
        #   * +rates+ [Array<Hash>] array with rates hashes
        #   * +stay_length+ [Integer] number of days for which rates are
        #                             fetched for
        #
        # Returns [Array] wrapping [SAW::Entities::UnitsPricing] objects
        def build(rates, stay_length)
          rates.map do |rate|
            safe_hash = Concierge::SafeAccessHash.new(rate)
            build_units_pricing(safe_hash, stay_length)
          end.compact
        end

        private
        def build_units_pricing(hash, stay_length)
          return nil if empty_unit_rates?(hash)

          Entities::UnitsPricing.new(
            property_id: hash.get("@id"),
            units:       build_units(hash, stay_length),
            currency:    parse_currency(hash)
          )
        end

        def parse_currency(hash)
          hash.get("currency_code")
        end

        def empty_unit_rates?(hash)
          units_hash(hash).nil?
        end

        def units_hash(hash)
          hash.get("apartments.accommodation_type.property_accommodation")
        end

        def build_units(hash, stay_length)
          units = units_hash(hash)

          Array(units).map do |unit_hash|
            safe_hash = Concierge::SafeAccessHash.new(unit_hash)
            price_per_period = parse_price(safe_hash)

            # since it's average prices, we don't need high precision
            price_per_night = (price_per_period / stay_length).round(2)

            Entities::UnitRate.new(
              id: safe_hash.get("@id"),
              price: price_per_night,
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
