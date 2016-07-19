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
        property = Roomorama::Property.new(safe_hash.get("id"))
        property.title     = safe_hash.get("data.name")
        property.type      = safe_hash.get("type")
        property.lat       = safe_hash.get("data.latitude")
        property.lng       = safe_hash.get("data.longitude")
        property.currency  = safe_hash.get("data.currency")
        property.city      = safe_hash.get("data.city")
        property.address   = full_address(safe_hash)
        property.amenities = amenities(safe_hash.get("data.facilities"))
        
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
