module RentalsUnited
  module Dictionaries
    # +RentalsUnited::Dictionaries::PropertyTypes+
    #
    # This class is responsible for mapping property types between RU and
    # Roomorama APIs.
    class PropertyTypes
      class << self
        # Find property type by its id
        #
        # Arguments
        #
        #   * +id+ [String] id of property type
        #
        # Usage
        #
        #   RentalsUnited::Dictionaries::PropertyTypes.find("35")
        #
        # Returns [Entities::PropertyType] property type object
        def find(id)
          all.find { |p| p.id == id }
        end

        # Find all property types
        #
        # Returns [Array<Entities::PropertyType>] array of property types
        def all
          @all ||= property_hashes.map do |hash|
            Entities::PropertyType.new(
              id: hash["id"],
              name: hash["rentals_united_name"],
              roomorama_name: hash["roomorama_name"],
              roomorama_subtype_name: hash["roomorama_subtype_name"]
            )
          end
        end

        private
        def property_hashes
          JSON.parse(File.read(file_path))
        end

        def file_path
          Hanami.root.join(
            "lib/concierge/suppliers/rentals_united/dictionaries",
            "property_types.json"
          ).to_s
        end
      end
    end
  end
end
