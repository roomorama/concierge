module SAW
  module Mappers
    class BasicProperty
      ALLOWED_FIELDS = [
        :internal_id, :title, :description, :lat, :lon, :city, :neighborhood,
        :country_code, :currency_code, :multi_unit, :type,
        :nightly_rate, :weekly_rate, :monthly_rate
      ]

      class << self
        # Returns property with correct mapping for Roomorama API
        # It does not initantiate new hash object every time, it applies
        # modifications for a given hash (to save the time)
        def build(hash, country:)
          prepare_internal_id!(hash)
          prepare_room_type!(hash)
          prepare_title!(hash)
          prepare_description!(hash)
          prepare_address_information!(hash)
          prepare_country_code!(hash, country)
          prepare_currency_code!(hash)
          prepare_rates!(hash)
          add_multi_unit_flag!(hash)
          keep_only_needed_fields!(hash)
          
          Entities::BasicProperty.new(hash)
        end

        private

        def keep_only_needed_fields!(hash)
          hash.keep_if do |key, _|
            ALLOWED_FIELDS.include?(key)
          end
        end

        def prepare_internal_id!(hash)
          hash[:internal_id] = hash.delete("@id").to_i
        end
        
        def prepare_title!(hash)
          hash[:title] = hash.delete("name")
        end

        def prepare_description!(hash)
          hash[:description] = hash.delete("summary")
        end

        def prepare_address_information!(hash)
          location_info = hash["map_location"]

          # hash[:address]      = location_info["full_address"]
          hash[:lat]          = location_info["latitude"]
          hash[:lon]          = location_info["longitude"]
          hash[:city]         = hash["city_region"]
          hash[:neighborhood] = hash["location"]
        end

        def prepare_country_code!(hash, country_name)
          hash[:country_code] = Converters::CountryCode.code_by_name(
            country_name
          )
        end

        def prepare_currency_code!(hash)
          hash[:currency_code] = hash.delete("currency_code")
        end

        def prepare_rates!(hash)
          price = BigDecimal.new(hash.delete("price"))

          hash[:nightly_rate] = sprintf('%02.2f', price)
          hash[:weekly_rate] = sprintf('%02.2f', price * 7)
          hash[:monthly_rate] = sprintf('%02.2f', price * 30)
        end

        def prepare_room_type!(hash)
          hash[:type] = 'apartment'
        end

        def add_multi_unit_flag!(hash)
          hash[:multi_unit] = true
        end
      end
    end
  end
end
