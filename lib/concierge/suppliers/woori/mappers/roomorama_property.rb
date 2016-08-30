module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object.
    class RoomoramaProperty
      MINIMUM_STAY = 1
      DEFAULT_PROPERTY_RATE = 999999
      DEFAULT_PROPERTY_TYPE = 'apartment'
      CANCELLATION_POLICY = 'moderate'

      attr_reader :safe_hash, :amenities_converter, :country_code_converter,
                  :description_converter

      # Initialize RoomoramaProperty mapper
      #
      # Arguments:
      #
      #   * +safe_hash+ [Concierge::SafeAccessHash] property parameters
      def initialize(safe_hash)
        @safe_hash = safe_hash
        @amenities_converter = Converters::Amenities.new(safe_hash.get("data.facilities"))
        @country_code_converter = Converters::CountryCode.new
        @description_converter = Converters::Description.new(
          safe_hash.get("data.description"),
          amenities_converter
        )
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
        property.title                = safe_hash.get("data.name")
        property.type                 = DEFAULT_PROPERTY_TYPE
        property.lat                  = safe_hash.get("data.latitude")
        property.lng                  = safe_hash.get("data.longitude")
        property.currency             = safe_hash.get("data.currency")
        property.city                 = safe_hash.get("data.city")
        property.neighborhood         = safe_hash.get("data.region")
        property.postal_code          = safe_hash.get("data.postalCode")
        property.check_in_time        = check_in_time
        property.check_out_time       = check_out_time
        property.address              = full_address
        property.amenities            = amenities_converter.convert
        property.country_code         = country_code
        property.description          = description_converter.convert
        property.nightly_rate         = DEFAULT_PROPERTY_RATE
        property.weekly_rate          = DEFAULT_PROPERTY_RATE
        property.monthly_rate         = DEFAULT_PROPERTY_RATE
        property.minimum_stay         = MINIMUM_STAY
        property.cancellation_policy  = CANCELLATION_POLICY
        property.default_to_available = true
        property.instant_booking!
        property.multi_unit!

        set_images!(property)
        
        property
      end

      private
      def set_images!(property)
        image_hashes = Array(safe_hash.get("data.images"))

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
        times_array.find { |hash| hash["id"] == id }
      end

      def full_address
        address_1 = safe_hash.get("data.address1")
        address_2 = safe_hash.get("data.address2")

        [address_1, address_2].join(" ")
      end

      def country_code
        country_name = safe_hash.get("data.country")
        country_code_converter.code_by_name(country_name)
      end
    end
  end
end
