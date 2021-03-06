module SAW
  module Mappers
    # +SAW::Mappers::DetailedProperty+
    #
    # This class is responsible for building a
    # +SAW::Entities::DetailedProperty+ object from the hash which was fetched
    # from the SAW API.
    class DetailedProperty
      ALLOWED_FIELDS = [
        :internal_id, :type, :title, :description, :lat, :lon, :city,
        :neighborhood, :address, :country, :amenities, :multi_unit, :images,
        :postal_code, :not_supported_amenities, :bed_configurations,
        :property_accommodations, :owner_email, :owner_phone_number
      ]

      class << self
        # Builds a property
        #
        # Arguments:
        #
        #   * +attrs+ [Concierge::SafeAccessHash] property parameters
        #   * +image_url_rewrite+ [Boolean] whether or not rewrite image URLs
        #
        # Returns [SAW::Entities::DetailedProperty]
        def build(attrs, image_url_rewrite: false)
          new_hash = {}

          copy_internal_id!(attrs, new_hash)
          copy_title!(attrs, new_hash)
          copy_description!(attrs, new_hash)
          copy_address_information!(attrs, new_hash)
          copy_owner_information!(attrs, new_hash)
          copy_images!(attrs, new_hash, image_url_rewrite)
          copy_supported_amenities!(attrs, new_hash)
          copy_not_supported_amenities!(attrs, new_hash)
          copy_bed_configurations!(attrs, new_hash)
          copy_property_accomodations!(attrs, new_hash)
          add_multi_unit_flag!(new_hash)
          add_room_type!(new_hash)
          keep_only_needed_fields!(new_hash)

          safe_hash = Concierge::SafeAccessHash.new(new_hash)
          Entities::DetailedProperty.new(safe_hash)
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
          hash[:description] = attrs.get("property_description")
        end

        def copy_owner_information!(attrs, hash)
          hash[:owner_email] = attrs.get("email")
          hash[:owner_phone_number] = attrs.get("phone")
        end

        def copy_address_information!(attrs, hash)
          location_info = attrs.get("map_location")

          hash[:address]      = location_info.get("full_address")
          hash[:lat]          = location_info.get("latitude")
          hash[:lon]          = location_info.get("longitude")
          hash[:country]      = attrs.get("country")
          hash[:city]         = attrs.get("city_region")
          hash[:neighborhood] = attrs.get("location")
          hash[:postal_code]  = attrs.get("postalcode").to_s.strip
        end

        def copy_images!(attrs, hash, image_url_rewrite)
          hash[:images] = Mappers::RoomoramaImageSet.build(
            attrs,
            image_url_rewrite
          )
        end

        def copy_supported_amenities!(attrs, hash)
          hash[:amenities] = convert_amenities(attrs)
        end

        def copy_not_supported_amenities!(attrs, hash)
          hash[:not_supported_amenities] =
            convert_not_supported_amenities(attrs)
        end

        def copy_bed_configurations!(attrs, hash)
          hash[:bed_configurations] = attrs.get("beddingconfigurations")
        end

        def copy_property_accomodations!(attrs, hash)
          hash[:property_accommodations] = attrs.get("property_accommodations")
        end

        def add_room_type!(hash)
          hash[:type] = 'apartment'
        end

        def add_multi_unit_flag!(hash)
          hash[:multi_unit] = true
        end

        def convert_amenities(hash)
          saw_amenities = fetch_saw_amenities(hash)

          Converters::Amenities.convert(saw_amenities)
        end

        def convert_not_supported_amenities(hash)
          saw_amenities = fetch_saw_amenities(hash)

          Converters::Amenities.select_not_supported_amenities(saw_amenities)
        end

        def fetch_saw_amenities(hash)
          facility_services = hash.get("facility_services")

          if facility_services
            saw_amenities = Array(facility_services.get("facility_service"))
          else
            saw_amenities = []
          end

          if hash.get('flag_breakfast_included') == 'Y'
            saw_amenities << 'Breakfast'
          end

          saw_amenities
        end
      end
    end
  end
end
