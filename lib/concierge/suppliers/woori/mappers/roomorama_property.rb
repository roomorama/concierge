module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object.
    class RoomoramaProperty
      attr_reader :safe_hash, :amenities_converter, :country_code_converter

      # Initialize RoomoramaProperty mapper
      #
      # Arguments:
      #
      #   * +safe_hash+ [Concierge::SafeAccessHash] property parameters
      def initialize(safe_hash)
        @safe_hash = safe_hash
        @amenities_converter = Converters::Amenities.new
        @country_code_converter = Converters::CountryCode.new
      end

      # Builds Roomorama::Property object
      #
      # Usage:
      #
      #   Mappers::RoomoramaProperty.build(safe_hash)
      #
      # Returns +Roomorama::Property+ Roomorama property object
      def build_property
        property = Roomorama::Property.new(safe_hash.get("hash"))
        property.title          = safe_hash.get("data.name")
        property.type           = safe_hash.get("type")
        property.lat            = safe_hash.get("data.latitude")
        property.lng            = safe_hash.get("data.longitude")
        property.currency       = safe_hash.get("data.currency")
        property.city           = safe_hash.get("data.city")
        property.neighborhood   = safe_hash.get("data.region")
        property.postal_code    = safe_hash.get("data.postalCode")
        property.check_in_time  = check_in_time
        property.check_out_time = check_out_time
        property.address        = full_address
        property.amenities      = amenities
        property.country_code   = country_code
        property.description    = description_with_additional_amenities
        property.default_to_available = true
        property.instant_booking!
        property.multi_unit!

        set_images!(property)
        
        property
      end

      private
      def set_images!(property)
        image_hashes = safe_hash.get("data.images")

        mapper = Mappers::RoomoramaImageSet.new(image_hashes)
        mapper.build_images.each { |image| property.add_image(image) }
      end

      def check_in_time
        record = find_time_record_by_id("pension_chk_in")

        return nil unless record
        
        record["from"] 
      end

      def check_out_time
        record = find_time_record_by_id("pension_chk_out")
        
        return nil unless record
        
        record["to"] 
      end

      def find_time_record_by_id(id)
        times_array = safe_hash.get("data.times")
        times_array.select { |hash| hash["id"] == id  }.first
      end

      def full_address
        address_1 = safe_hash.get("data.address1")
        address_2 = safe_hash.get("data.address2")

        [address_1, address_2].join(" ")
      end

      def amenities
        woori_facilities = safe_hash.get("data.facilities")

        if woori_facilities && woori_facilities.any?
          amenities_converter.convert(woori_facilities)
        else
          [] 
        end
      end

      def country_code
        country_name = safe_hash.get("data.country")
        country_code_converter.code_by_name(country_name)
      end

      def additional_amenities
        woori_facilities = safe_hash.get("data.facilities")

        if woori_facilities && woori_facilities.any?
          amenities_converter.select_not_supported_amenities(woori_facilities)
        else
          [] 
        end
      end

      def description_with_additional_amenities
        description = safe_hash.get("data.description")
        
        text = description.to_s.strip.gsub(/\.\z/, "")
        text_amenities = formatted_additional_amenities

        description_parts = [text, text_amenities].reject(&:empty?)

        if description_parts.any?
          description_parts.join('. ')
        else
          nil
        end
      end

      def formatted_additional_amenities
        if additional_amenities.any?
          text = 'Additional amenities: '
          text += additional_amenities.join(', ')
        else
          ""
        end
      end
    end
  end
end
