module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Property+
    #
    # This class is responsible for building a
    # +RentalsUnited::Entities::Property+ object from a hash which was fetched
    # from the RentalsUnited API.
    class Property
      attr_reader :property_hash

      EN_DESCRIPTION_LANG_CODE = "1"

      # Initialize +RentalsUnited::Mappers::Property+
      #
      # Arguments:
      #
      #   * +property_hash+ [Concierge::SafeAccessHash] property hash object
      def initialize(property_hash)
        @property_hash = property_hash
      end

      # Builds a property
      #
      # Returns [RentalsUnited::Entities::Property]
      def build_property
        property = Entities::Property.new(
          id:                      property_hash.get("ID"),
          title:                   property_hash.get("Name"),
          lat:                     property_hash.get("Coordinates.Latitude").to_f,
          lng:                     property_hash.get("Coordinates.Longitude").to_f,
          address:                 property_hash.get("Street"),
          postal_code:             property_hash.get("ZipCode").to_s.strip,
          max_guests:              property_hash.get("CanSleepMax").to_i,
          bedroom_type_id:         property_hash.get("PropertyTypeID"),
          property_type_id:        property_hash.get("ObjectTypeID"),
          active:                  property_hash.get("IsActive"),
          archived:                property_hash.get("IsArchived"),
          surface:                 property_hash.get("Space").to_i,
          owner_id:                property_hash.get("OwnerID"),
          security_deposit_amount: property_hash.get("SecurityDeposit").to_f,
          security_deposit_type:   security_deposit_type,
          check_in_time:           check_in_time,
          check_out_time:          check_out_time,
          floor:                   floor,
          description:             en_description(property_hash),
          images:                  build_images,
          amenities:               build_amenities
        )

        property
      end

      private
      def build_amenities
        Array(property_hash.get("Amenities.Amenity"))
      end

      def build_images
        raw_images = Array(property_hash.get("Images.Image"))

        mapper = Mappers::ImageSet.new(raw_images)
        mapper.build_images
      end

      # RU sends -1000 for Basement
      #              0 for Ground
      #         0..100 for usual floor number
      #
      # Replace -1000 with just -1 because we don't want our users to
      # be burnt away -1000 floors under the earth.
      def floor
        ru_floor_value = property_hash.get("Floor").to_i
        return -1 if ru_floor_value == -1000
        return ru_floor_value
      end

      def en_description(hash)
        descriptions = hash.get("Descriptions.Description")
        en_description = Array(descriptions).find do |desc|
          desc["@LanguageID"] == EN_DESCRIPTION_LANG_CODE
        end

        en_description["Text"] if en_description
      end

      def security_deposit_type
        security_deposit = property_hash.get("SecurityDeposit")

        if security_deposit
          security_deposit.attributes["DepositTypeID"]
        end
      end

      def check_in_time
        from = property_hash.get("CheckInOut.CheckInFrom")
        to   = property_hash.get("CheckInOut.CheckInTo")

        "#{from}-#{to}" if from && to
      end

      def check_out_time
        property_hash.get("CheckInOut.CheckOutUntil")
      end
    end
  end
end
