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
      BATHROOM_TYPE_ID = "81"

      # Bed configuration mapping (key -> value)
      #
      # key:   RU amenity code
      # value: Multiplier, which shows how many beds we should count for
      #        every occurence of the given amenity code
      #
      # For the most beds value is 1, but due to the nature of some kind of
      # beds (Twin, Bunk), this value can be different from 1.
      SINGLE_BED_CODES = {
        "323" => 1, # single bed
        "209" => 1, # Extra Bed
        "440" => 2, # Pair of twin beds
        "444" => 2, # Bunk bed
      }
      DOUBLE_BED_CODES = {
        "61"  => 1,  # double bed
        "324" => 1, # king size bed
        "485" => 1, # Queen size bed
      }
      SOFA_BED_CODES = {
        "237" => 1, # sofabed
        "182" => 1, # sofa
        "200" => 1, # double sofa bed
        "203" => 1, # double sofa
      }

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
          check_in_instructions:   check_in_instructions,
          floor:                   floor,
          description:             en_description(property_hash),
          images:                  build_images,
          amenities:               build_amenities,
          number_of_bathrooms:     number_of_bathrooms,
          number_of_single_beds:   beds_count(SINGLE_BED_CODES),
          number_of_double_beds:   beds_count(DOUBLE_BED_CODES),
          number_of_sofa_beds:     beds_count(SOFA_BED_CODES),
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

      def rooms
        @rooms ||= begin
          path = "CompositionRoomsAmenities.CompositionRoomAmenities"

          Array(property_hash.get(path)).map do |room_hash|
            Concierge::SafeAccessHash.new(room_hash)
          end
        end
      end

      def number_of_bathrooms
        rooms.inject(0) do |count, room_hash|
          if room_hash.get("@CompositionRoomID") == BATHROOM_TYPE_ID
            count = count + 1
          else
            count
          end
        end
      end

      def beds_count(bed_codes)
        count = 0

        rooms.each do |room_hash|
          room_amenities = Array(room_hash.get("Amenities.Amenity"))

          room_amenities.each do |amenity|
            if bed_codes.has_key?(amenity)
              multiplier = bed_codes[amenity]
              count = count + multiplier * amenity.attributes["Count"].to_i
            end
          end
        end

        count
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

      def check_in_instructions
        info = property_hash.get("ArrivalInstructions")
        return nil unless info

        instructions = {}
        simple_keys = %w(Landlord Email Phone DaysBeforeArrival)
        localized_keys = %w(PickupService HowToArrive)

        simple_keys.each do |key|
          value = info.get(key)
          instructions[key] = value if value
        end

        localized_keys.each do |key|
          value = en_lang_field("ArrivalInstructions.#{key}")
          instructions[key] = value if value
        end

        instructions.map { |key, value| "#{key}: #{value}" }.join("\n")
      end

      def en_lang_field(key)
        multi_lang_values = property_hash.get(key)
        en_value = Array(multi_lang_values).find do |field|
          text = field["Text"]
          next unless text

          text.attributes["LanguageID"] == EN_DESCRIPTION_LANG_CODE
        end

        en_value["Text"] if en_value
      end
    end
  end
end
