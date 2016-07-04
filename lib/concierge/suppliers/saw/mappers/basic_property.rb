module SAW
  module Mappers
    # +SAW::Mappers::BasicProperty+
    #
    # This class is responsible for building a +SAW::Entities::BasicProperty+ 
    # object from the hash which was fetched from the SAW API.
    class BasicProperty
      ALLOWED_FIELDS = [
        :internal_id, :title, :description, :lat, :lon, :city, :neighborhood,
        :country_code, :currency_code, :multi_unit, :type,
        :nightly_rate, :weekly_rate, :monthly_rate
      ]

      class << self
        # Builds a property
        #
        # Arguments:
        #
        #   * +hash+ [Concierge::SafeAccessHash] property parameters
        #   * +country+ [SAW::Entities::Country] country of the property
        #
        # Returns [SAW::Entities::BasicProperty]
        def build(attrs, country:)
          new_hash = {}

          copy_internal_id!(attrs, new_hash)
          copy_title!(attrs, new_hash)
          copy_description!(attrs, new_hash)
          copy_address_information!(attrs, new_hash)
          copy_currency_code!(attrs, new_hash)
          copy_rates!(attrs, new_hash)
          add_country_code!(new_hash, country)
          add_multi_unit_flag!(new_hash)
          add_room_type!(new_hash)
          keep_only_needed_fields!(new_hash)
          
          safe_hash = Concierge::SafeAccessHash.new(new_hash)
          Entities::BasicProperty.new(safe_hash)
        end

        private

        def keep_only_needed_fields!(hash)
          hash.keep_if { |key, _| ALLOWED_FIELDS.include?(key) }
        end

        def copy_internal_id!(attrs, hash)
          hash[:internal_id] = attrs.get("@id").to_i
        end
        
        def copy_title!(attrs, hash)
          hash[:title] = attrs.get("name")
        end

        def copy_description!(attrs, hash)
          hash[:description] = attrs.get("summary")
        end

        def copy_address_information!(attrs, hash)
          location_info = attrs.get("map_location")

          hash[:lat]          = location_info.get("latitude")
          hash[:lon]          = location_info.get("longitude")
          hash[:city]         = attrs.get("city_region")
          hash[:neighborhood] = attrs.get("location")
        end

        def copy_currency_code!(attrs, hash)
          hash[:currency_code] = attrs.get("currency_code")
        end

        def copy_rates!(attrs, hash)
          price = BigDecimal.new(attrs.get("price"))

          hash[:nightly_rate] = sprintf('%02.2f', price)
          hash[:weekly_rate] = sprintf('%02.2f', price * 7)
          hash[:monthly_rate] = sprintf('%02.2f', price * 30)
        end

        def add_room_type!(hash)
          hash[:type] = 'apartment'
        end

        def add_multi_unit_flag!(hash)
          hash[:multi_unit] = true
        end
        
        def add_country_code!(hash, country_name)
          hash[:country_code] = Converters::CountryCode.code_by_name(
            country_name
          )
        end
      end
    end
  end
end
