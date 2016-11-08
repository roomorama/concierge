module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object
    class RoomoramaProperty
      attr_reader :ru_property, :location, :owner, :seasons

      EN_DESCRIPTION_LANG_CODE = "1"
      CANCELLATION_POLICY = Roomorama::CancellationPolicy::SUPER_STRICT
      DEFAULT_PROPERTY_RATE = "9999"
      MINIMUM_STAY = 1
      SURFACE_UNIT = "metric"

      # List of supported by Roomorama security deposit types
      NO_DEPOSIT_ID = "1"
      FLAT_AMOUNT_PER_STAY_ID = "5"
      SUPPORTED_SECURITY_DEPOSIT_TYPES = [
        NO_DEPOSIT_ID,
        FLAT_AMOUNT_PER_STAY_ID
      ]
      SECURITY_DEPOSIT_PAYMENT_TYPE = 'cash'

      # Initialize +RentalsUnited::Mappers::Property+
      #
      # Arguments:
      #
      #   * +ru_property+ [Entities::Property] RU property object
      #   * +location+    [Entities::Location] location object
      #   * +owner+       [Entities::OwnerID] owner object
      #   * +seasons+     [Array<Entities::Season] seasons
      def initialize(ru_property, location, owner, seasons)
        @ru_property = ru_property
        @location = location
        @owner = owner
        @seasons = seasons
      end

      # Builds a property
      #
      # Returns a +Result+ wrapping +Roomorama::Property+ object
      # Returns a +Result+ with +Result::Error+ when operation fails
      def build_roomorama_property
        return archived_error         if ru_property.archived?
        return not_active_error       unless ru_property.active?
        return property_type_error    unless supported_property_type?
        return security_deposit_error unless supported_security_deposit?
        return no_seasons_error       unless has_seasons?

        property = Roomorama::Property.new(ru_property.id)
        property.title                 = ru_property.title
        property.description           = ru_property.description
        property.lat                   = ru_property.lat
        property.lng                   = ru_property.lng
        property.address               = ru_property.address
        property.postal_code           = ru_property.postal_code
        property.check_in_time         = ru_property.check_in_time
        property.check_out_time        = ru_property.check_out_time
        property.check_in_instructions = ru_property.check_in_instructions
        property.max_guests            = ru_property.max_guests
        property.surface               = ru_property.surface
        property.floor                 = ru_property.floor
        property.number_of_bathrooms   = ru_property.number_of_bathrooms
        property.number_of_single_beds = ru_property.number_of_single_beds
        property.number_of_double_beds = ru_property.number_of_double_beds
        property.number_of_sofa_beds   = ru_property.number_of_sofa_beds
        property.country_code          = country_code(location)
        property.currency              = location.currency
        property.city                  = location.city
        property.neighborhood          = location.neighborhood
        property.owner_name            = full_name(owner)
        property.owner_email           = owner.email
        property.owner_phone_number    = owner.phone
        property.number_of_bedrooms    = number_of_bedrooms
        property.amenities             = amenities_dictionary.convert
        property.pets_allowed          = amenities_dictionary.pets_allowed?
        property.smoking_allowed       = amenities_dictionary.smoking_allowed?
        property.type                  = property_type.roomorama_name
        property.subtype               = property_type.roomorama_subtype_name
        property.surface_unit          = SURFACE_UNIT
        property.nightly_rate          = DEFAULT_PROPERTY_RATE
        property.weekly_rate           = DEFAULT_PROPERTY_RATE
        property.monthly_rate          = DEFAULT_PROPERTY_RATE
        property.minimum_stay          = MINIMUM_STAY
        property.cancellation_policy   = CANCELLATION_POLICY
        property.default_to_available  = false
        property.instant_booking!

        set_images!(property)
        set_security_deposit!(property)
        set_rates!(property)
        set_cleaning!(property)
        set_description_append!(property)

        Result.new(property)
      end

      private
      def set_images!(property)
        ru_property.images.each { |image| property.add_image(image) }
      end

      def set_security_deposit!(property)
        if ru_property.security_deposit_type == FLAT_AMOUNT_PER_STAY_ID
          property.security_deposit_amount = ru_property.security_deposit_amount
          property.security_deposit_currency_code = property.currency
          property.security_deposit_type = SECURITY_DEPOSIT_PAYMENT_TYPE
        end
      end

      def set_rates!(property)
        property.nightly_rate = avg_price_per_day.round(2)
        property.weekly_rate  = (avg_price_per_day * 7).round(2)
        property.monthly_rate = (avg_price_per_day * 30).round(2)
      end

      # Cleaning is always included to total price while quote/booking
      # There is no need for user to pay cleaning additionally
      def set_cleaning!(property)
        property.services_cleaning = false
        property.services_cleaning_required = nil
        property.services_cleaning_rate = nil
      end

      def avg_price_per_day
        @avg_price ||= calculate_avg_price_per_day
      end

      def calculate_avg_price_per_day
        full_price = seasons.inject(0) do |sum, season|
          sum += season.number_of_days * season.price
        end

        total_days = seasons.map(&:number_of_days).inject(:+)
        (full_price / total_days).to_f
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

      def set_description_append!(property)
        converter = Converters::CheckInOutFees.new(ru_property, location.currency)
        tranlations = converter.build_tranlations

        if tranlations
          property.description_append    = tranlations.fetch(:en)
          property.zh.description_append = tranlations.fetch(:zh)
          property.de.description_append = tranlations.fetch(:de)
          property.es.description_append = tranlations.fetch(:es)
        end
      end

      def supported_property_type?
        !!property_type
      end

      def supported_security_deposit?
        SUPPORTED_SECURITY_DEPOSIT_TYPES.include?(
          ru_property.security_deposit_type
        )
      end

      def has_seasons?
        seasons.any?
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

      def security_deposit_error
        Result.error(:security_deposit_not_supported)
      end

      def no_seasons_error
        Result.error(:empty_seasons)
      end

      def amenities_dictionary
        @amenities_dictionary ||= Dictionaries::Amenities.new(
          ru_property.amenities
        )
      end
    end
  end
end
