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
    end
  end
end
