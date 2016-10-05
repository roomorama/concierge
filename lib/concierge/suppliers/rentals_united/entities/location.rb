module RentalsUnited
  module Entities
    # +RentalsUnited::Entities::Location+
    #
    # This entity represents a location type object.
    class Location
      attr_accessor :id, :neighborhood, :city, :region, :country, :currency

      def initialize(id)
        @id = id
      end

      def load(attrs)
        self.neighborhood = attrs[:neighborhood]
        self.city = attrs[:city]
        self.region = attrs[:region]
        self.country = attrs[:country]
        self
      end
    end
  end
end
