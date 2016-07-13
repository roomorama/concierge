module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaProperty+
    #
    class RoomoramaProperty
      # Bulds Roomorama::Property object
      #
      # Returns [Roomorama::Property] Roomorama property
      def self.build(hash)
        Roomorama::Property.new(hash.get("id"))
      end
    end
  end
end
