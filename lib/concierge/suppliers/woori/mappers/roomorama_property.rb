module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object.
    class RoomoramaProperty
      # Builds Roomorama::Property object
      #
      # Arguments:
      #
      #   * +safe_hash+ [Concierge::SafeAccessHash] property parameters
      #
      # Usage:
      #
      #   Mappers::RoomoramaProperty.build(safe_hash)
      #
      # Returns +Roomorama::Property+ Roomorama property object
      def self.build(safe_hash)
        property = Roomorama::Property.new(safe_hash.get("hash"))
        property.title          = safe_hash.get("data.name")
        property.type           = safe_hash.get("type")
        property.lat            = safe_hash.get("data.latitude")
        property.lng            = safe_hash.get("data.longitude")
        property.currency       = safe_hash.get("data.currency")
        property.city           = safe_hash.get("data.city")
        property.neighborhood   = safe_hash.get("data.region")
        property.postal_code    = safe_hash.get("data.postalCode")
        property.check_in_time  = check_in_time(safe_hash.get("data.times"))
        property.check_out_time = check_out_time(safe_hash.get("data.times"))
        property.address        = full_address(safe_hash)
        property.amenities      = amenities(safe_hash.get("data.facilities"))
        property.country_code   = country_code(safe_hash.get("data.country"))
        
        property.description = description_with_additional_amenities(
          safe_hash.get("data.description"),
          additional_amenities(safe_hash.get("data.facilities"))
        )
        
        set_images!(property, safe_hash.get("data.images"))
        
        property.default_to_available = true
        property.instant_booking!
        property.multi_unit!

        property
      end

      private
      def self.set_images!(property, image_hashes)
        images = Mappers::RoomoramaImageSet.build(image_hashes)
        images.each { |image| property.add_image(image) }
      end

      def self.check_in_time(times_array)
        record = find_time_record_by_id(times_array, "pension_chk_in")

        return nil unless record
        
        record["from"] 
      end
      
      def self.check_out_time(times_array)
        record = find_time_record_by_id(times_array, "pension_chk_out")
        
        return nil unless record
        
        record["to"] 
      end

      def self.find_time_record_by_id(times_array, id)
        times_array.select { |hash| hash["id"] == id  }.first
      end

      def self.full_address(safe_hash)
        address_1 = safe_hash.get("data.address1")
        address_2 = safe_hash.get("data.address2")

        [address_1, address_2].join(" ")
      end

      def self.amenities(woori_facilities)
        if woori_facilities && woori_facilities.any?
          Converters::Amenities.convert(woori_facilities)
        else
          [] 
        end
      end

      def self.country_code(country_name)
        Converters::CountryCode.code_by_name(country_name)
      end

      def self.additional_amenities(woori_facilities)
        if woori_facilities && woori_facilities.any?
          Converters::Amenities.select_not_supported_amenities(woori_facilities)
        else
          [] 
        end
      end
      
      def self.description_with_additional_amenities(description, amenities)
        text = description.to_s.strip.gsub(/\.\z/, "")
        text_amenities = formatted_additional_amenities(amenities)

        description_parts = [text, text_amenities].reject(&:empty?)

        if description_parts.any?
          description_parts.join('. ')
        else
          nil
        end
      end
      
      def self.formatted_additional_amenities(amenities)
        if amenities.any?
          text = 'Additional amenities: '
          text += amenities.join(', ')
        else
          ""
        end
      end
    end
  end
end
