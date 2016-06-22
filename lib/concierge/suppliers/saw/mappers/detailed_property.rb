module SAW
  module Mappers
    class DetailedProperty
      ALLOWED_FIELDS = [
        :internal_id, :type, :title, :description, :lat, :lon, :city,
        :neighborhood, :address, :country, :amenities, :multi_unit, :images,
        :not_supported_amenities, :bed_configurations, :property_accommodations
      ]

      class << self
        # Returns property with correct mapping for Roomorama API
        # It does not initantiate new hash object every time, it applies
        # modifications for a given hash (to save the time)
        def build(hash, image_url_rewrite: false)
          attrs = hash.dup

          prepare_internal_id!(attrs)
          prepare_room_type!(attrs)
          prepare_title!(attrs)
          prepare_description!(attrs)
          prepare_address_information!(attrs)
          prepare_images!(attrs, image_url_rewrite)
          prepare_supported_amenities!(attrs)
          prepare_not_supported_amenities!(attrs)
          prepare_bed_configurations!(attrs)
          prepare_property_accomodations!(attrs)
          add_multi_unit_flag!(attrs)
          keep_only_needed_fields!(attrs)
          
          Entities::DetailedProperty.new(attrs)
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
          hash[:description] = hash.delete("property_description")
        end

        def prepare_address_information!(hash)
          location_info = hash["map_location"]

          hash[:address]      = location_info["full_address"]
          hash[:lat]          = location_info["latitude"]
          hash[:lon]          = location_info["longitude"]
          hash[:country]      = hash["country"]
          hash[:city]         = hash["city_region"]
          hash[:neighborhood] = hash["location"]
        end

        def prepare_images!(hash, image_url_rewrite)
          hash[:images] = Mappers::RoomoramaImageSet.build(
            hash,
            image_url_rewrite
          ) 
        end

        def prepare_supported_amenities!(hash)
          hash[:amenities] = convert_amenities(hash)
        end
        
        def prepare_not_supported_amenities!(hash)
          hash[:not_supported_amenities] = 
            convert_not_supported_amenities(hash)
        end

        def prepare_bed_configurations!(hash)
          hash[:bed_configurations] = hash.fetch("beddingconfigurations")
        end
        
        def prepare_property_accomodations!(hash)
          hash[:property_accommodations] = hash["property_accommodations"]
        end

        def prepare_room_type!(hash)
          hash[:type] = 'apartment'
        end

        def add_multi_unit_flag!(hash)
          hash[:multi_unit] = true
        end

        def convert_amenities(hash)
          saw_amenities = fetch_saw_amenities(hash)
          
          if saw_amenities.any?
            Converters::Amenities.convert(saw_amenities)
          else
            return [] 
          end
        end

        def convert_not_supported_amenities(hash)
          saw_amenities = fetch_saw_amenities(hash)
          
          if saw_amenities.any?
            Converters::Amenities.select_not_supported_amenities(saw_amenities)
          else
            return [] 
          end
        end

        def fetch_saw_amenities(hash)
          facility_services = hash.fetch("facility_services", {})
          
          if facility_services
            saw_amenities = Array(facility_services.fetch("facility_service", {}))
          else
            saw_amenities = []
          end
          
          if hash['flag_breakfast_included'] == 'Y'
            saw_amenities << 'Breakfast' 
          end

          saw_amenities
        end
      end
    end
  end
end
