module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Property+
    #
    # This class is responsible for building a
    # +RentalsUnited::Entities::Property+ object from a hash which was fetched
    # from the RentalsUnited API.
    class Property
      attr_reader :property_hash, :location, :amenities_dictionary

      EN_DESCRIPTION_LANG_CODE = "1"
      CANCELLATION_POLICY = "strict"
      DEFAULT_PROPERTY_RATE = "9999"
      MINIMUM_STAY = 1

      # Initialize +RentalsUnited::Mappers::Property+
      #
      # Arguments:
      #
      #   * +property_hash+ [Concierge::SafeAccessHash] property hash object
      #   * +location+ [Entities::Location] location object
      def initialize(property_hash, location)
        @property_hash = property_hash
        @location = location
        @amenities_dictionary = Dictionaries::Amenities.new(
          property_hash.get("Amenities.Amenity")
        )
      end

      # Builds a property
      #
      # Returns [RentalsUnited::Entities::Property]
      def build_property
        property = Roomorama::Property.new(property_hash.get("ID"))
        property.title                = property_hash.get("Name")
        property.description          = en_description(property_hash)
        property.lat                  = property_hash.get("Coordinates.Latitude").to_f
        property.lng                  = property_hash.get("Coordinates.Longitude").to_f
        property.address              = property_hash.get("Street")
        property.postal_code          = property_hash.get("ZipCode")
        property.amenities            = amenities_dictionary.convert
        property.check_in_time        = check_in_time
        property.check_out_time       = check_out_time
        property.country_code         = country_code(location)
        property.currency             = location.currency
        property.city                 = location.city
        property.neighborhood         = location.neighborhood
        property.max_guests           = property_hash.get("CanSleepMax").to_i
        property.number_of_bedrooms   = number_of_bedrooms
        property.nightly_rate         = DEFAULT_PROPERTY_RATE
        property.weekly_rate          = DEFAULT_PROPERTY_RATE
        property.monthly_rate         = DEFAULT_PROPERTY_RATE
        property.minimum_stay         = MINIMUM_STAY
        property.cancellation_policy  = CANCELLATION_POLICY
        property.default_to_available = false
        property.instant_booking!

        property_type = find_property_type(property_hash.get("ObjectTypeID"))

        if property_type
          property.type = property_type.roomorama_name
          property.subtype = property_type.roomorama_subtype_name
        end

        set_images!(property)

        property
      end

      private
      def set_images!(property)
        raw_images = Array(property_hash.get("Images.Image"))

        mapper = Mappers::ImageSet.new(raw_images)
        mapper.build_images.each { |image| property.add_image(image) }
      end

      def find_property_type(id)
        RentalsUnited::Dictionaries::PropertyTypes.find(id)
      end

      def number_of_bedrooms
        RentalsUnited::Dictionaries::Bedrooms.count_by_type_id(
          property_hash.get("PropertyTypeID")
        )
      end

      def en_description(hash)
        descriptions = hash.get("Descriptions.Description")
        en_description = Array(descriptions).find do |desc|
          desc["@LanguageID"] == EN_DESCRIPTION_LANG_CODE
        end

        en_description["Text"] if en_description
      end

      def check_in_time
        from = property_hash.get("CheckInOut.CheckInFrom")
        to   = property_hash.get("CheckInOut.CheckInTo")

        "#{from}-#{to}" if from && to
      end

      def check_out_time
        property_hash.get("CheckInOut.CheckOutUntil")
      end

      def country_code(location)
        Converters::CountryCode.code_by_name(location.country)
      end
    end
  end
end
