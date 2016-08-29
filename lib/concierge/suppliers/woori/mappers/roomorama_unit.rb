module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaUnit+
    #
    # This class is responsible for building a +Roomorama::Unit+ object.
    class RoomoramaUnit
      DEFAULT_UNIT_RATE = 999999

      attr_reader :safe_hash, :amenities_converter
      
      # Initialize RoomoramaUnit mapper
      #
      # Arguments:
      #
      #   * +safe_hash+ [Concierge::SafeAccessHash] unit parameters
      def initialize(safe_hash)
        @safe_hash = safe_hash
        @amenities_converter = Converters::Amenities.new(safe_hash.get("data.facilities"))
      end

      # Builds Roomorama::Unit object
      #
      # It skips mapping the +description+ unit field due to auto-translated
      # bad descriptions coming from Woori.
      #
      # Arguments:
      #
      #   * +safe_hash+ [Concierge::SafeAccessHash] unit parameters
      #
      # Usage:
      #
      #   Mappers::RoomoramaUnit.build(safe_hash)
      #
      # Returns +Roomorama::Unit+ Roomorama unit object
      def build_unit
        unit = Roomorama::Unit.new(safe_hash.get("hash"))

        unit.title              = safe_hash.get("data.name")
        unit.description        = nil
        unit.amenities          = amenities_converter.convert
        unit.max_guests         = safe_hash.get("data.capacity")
        unit.number_of_bedrooms = safe_hash.get("data.roomCount")
        unit.number_of_units    = 1
        unit.nightly_rate       = DEFAULT_UNIT_RATE
        unit.weekly_rate        = DEFAULT_UNIT_RATE
        unit.monthly_rate       = DEFAULT_UNIT_RATE

        set_images!(unit)

        unit
      end

      private
      def set_images!(unit)
        image_hashes = Array(safe_hash.get("data.images"))

        mapper = Mappers::RoomoramaImageSet.new(image_hashes)
        mapper.build_images.each { |image| unit.add_image(image) }
      end
    end
  end
end
