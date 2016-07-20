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
        unit.description = safe_hash.get("data.description")

        unit
      end
    end
  end
end
