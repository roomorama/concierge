module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object
    class RoomoramaProperty
      attr_reader :ru_property, :location, :owner

      EN_DESCRIPTION_LANG_CODE = "1"
      CANCELLATION_POLICY = "super_elite"
      DEFAULT_PROPERTY_RATE = "9999"
      MINIMUM_STAY = 1
      SURFACE_UNIT = "metric"

      # Initialize +RentalsUnited::Mappers::Property+
      #
      # Arguments:
      #
      #   * +ru_property+ [Entities::Property] RU property object
      #   * +location+    [Entities::Location] location object
      #   * +owner+       [Entities::OwnerID] owner object
      def initialize(ru_property, location, owner)
        @ru_property = ru_property
        @location = location
        @owner = owner
      end

      # Builds a property
      #
      # Returns a +Result+ wrapping +Roomorama::Property+ object
      # Returns a +Result+ with +Result::Error+ when operation fails
      def build_roomorama_property
        return archived_error      if ru_property.archived?
        return not_active_error    unless ru_property.active?
        return property_type_error unless supported_property_type?

        property = Roomorama::Property.new(ru_property.id)
        property.title                = ru_property.title
        property.description          = ru_property.description
        property.lat                  = ru_property.lat
        property.lng                  = ru_property.lng
        property.address              = ru_property.address
        property.postal_code          = ru_property.postal_code
        property.check_in_time        = ru_property.check_in_time
        property.check_out_time       = ru_property.check_out_time
        property.max_guests           = ru_property.max_guests
        property.surface              = ru_property.surface
        property.floor                = ru_property.floor
        property.country_code         = country_code(location)
        property.currency             = location.currency
        property.city                 = location.city
        property.neighborhood         = location.neighborhood
        property.owner_name           = full_name(owner)
        property.owner_email          = owner.email
        property.owner_phone_number   = owner.phone
        property.number_of_bedrooms   = number_of_bedrooms
        property.amenities            = amenities_dictionary.convert
        property.pets_allowed         = amenities_dictionary.pets_allowed?
        property.smoking_allowed      = amenities_dictionary.smoking_allowed?
        property.type                 = property_type.roomorama_name
        property.subtype              = property_type.roomorama_subtype_name
        property.surface_unit         = SURFACE_UNIT
        property.nightly_rate         = DEFAULT_PROPERTY_RATE
        property.weekly_rate          = DEFAULT_PROPERTY_RATE
        property.monthly_rate         = DEFAULT_PROPERTY_RATE
        property.minimum_stay         = MINIMUM_STAY
        property.cancellation_policy  = CANCELLATION_POLICY
        property.default_to_available = false
        property.instant_booking!

        set_images!(property)

        Result.new(property)
      end

      private
      def set_images!(property)
        ru_property.images.each { |image| property.add_image(image) }
      end

      def full_name(owner)
        [owner.first_name, owner.last_name].join(" ").strip
      end

      def number_of_bedrooms
        RentalsUnited::Dictionaries::Bedrooms.count_by_type_id(
          ru_property.bedroom_type_id
        )
      end

      def country_code(location)
        Converters::CountryCode.code_by_name(location.country)
      end

      def supported_property_type?
        !!property_type
      end

      def property_type
        @property_type ||= Dictionaries::PropertyTypes.find(
          ru_property.property_type_id
        )
      end

      def property_type_error
        Result.error(:property_type_not_supported)
      end

      def archived_error
        Result.error(:attempt_to_build_archived_property)
      end

      def not_active_error
        Result.error(:attempt_to_build_not_active_property)
      end

      def amenities_dictionary
        @amenities_dictionary ||= Dictionaries::Amenities.new(
          ru_property.amenities
        )
      end
    end
  end
end
