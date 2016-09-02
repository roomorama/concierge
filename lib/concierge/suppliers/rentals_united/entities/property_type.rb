module RentalsUnited
  module Entities
    # +RentalsUnited::Entities::PropertyType+
    #
    # This entity represents a property type object.
    #
    # Attributes:
    #
    # +id+                     - rentals united property type id
    # +name+                   - rentals united property type name
    # +roomorama_name+         - roomorama name
    # +roomorama_subtype_name+ - roomorama subtype name
    class PropertyType
      attr_reader :id, :name, :roomorama_name, :roomorama_subtype_name

      def initialize(id:, name:, roomorama_name:, roomorama_subtype_name:)
        @id = id
        @name = name
        @roomorama_name = roomorama_name
        @roomorama_subtype_name = roomorama_subtype_name
      end
    end
  end
end
