module RentalsUnited
  module Dictionaries
    class PropertyTypes
      class << self
        def find(id)
          all.find { |p| p.id == id }
        end

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
