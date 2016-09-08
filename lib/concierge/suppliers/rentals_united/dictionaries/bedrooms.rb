module RentalsUnited
  module Dictionaries
    # +RentalsUnited::Dictionaries::Bedrooms+
    #
    # This class is responsible for bedrooms count mapping to bedrooms type ids
    class Bedrooms
      class << self
        # Find bedrooms count by bedroom type id
        #
        # Arguments
        #
        #   * +id+ [String] id of bedroom type
        #
        # Usage
        #
        #   RentalsUnited::Dictionaries::Bedrooms.count_by_type_id("1")
        #
        # Returns [Integer] bedrooms count
        def count_by_type_id(id)
          type = bedrooms.find { |bedroom| bedroom["type_id"] == id }
          return nil unless type

          type["bedrooms"]
        end

        private
        def bedrooms
          JSON.parse(File.read(file_path))
        end

        def file_path
          Hanami.root.join(
            "lib/concierge/suppliers/rentals_united/dictionaries",
            "bedrooms.json"
          ).to_s
        end
      end
    end
  end
end
