module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaUnit+
    #
    # This class is responsible for building a +Roomorama::Unit+ object.
    class RoomoramaUnit
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
      def self.build(safe_hash)
        unit = Roomorama::Unit.new(safe_hash.get("hash"))

        unit.title       = safe_hash.get("data.name")
        unit.max_guests  = safe_hash.get("data.capacity")
        unit.amenities   = amenities(safe_hash.get("data.facilities"))
        
        unit.description = description_with_additional_amenities(
          safe_hash.get("data.description"),
          additional_amenities(safe_hash.get("data.facilities"))
        )

        unit
      end

      private

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
