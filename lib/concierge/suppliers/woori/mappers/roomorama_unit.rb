module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaUnit+
    #
    # This class is responsible for building a +Roomorama::Unit+ object.
    class RoomoramaUnit
      attr_reader :safe_hash, :amenities_converter
      
      # Initialize RoomoramaUnit mapper
      #
      # Arguments:
      #
      #   * +safe_hash+ [Concierge::SafeAccessHash] unit parameters
      def initialize(safe_hash)
        @safe_hash = safe_hash
        @amenities_converter = Converters::Amenities.new
      end

      # Builds Roomorama::Unit object
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

        unit.title       = safe_hash.get("data.name")
        unit.max_guests  = safe_hash.get("data.capacity")
        unit.amenities   = amenities
        unit.description = description_with_additional_amenities

        unit
      end

      private
      def amenities
        woori_facilities = safe_hash.get("data.facilities")

        if woori_facilities && woori_facilities.any?
          amenities_converter.convert(woori_facilities)
        else
          [] 
        end
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
