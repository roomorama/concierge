module RentalsUnited
  module Dictionaries
    # +RentalsUnited::Dictionaries::Statuses+
    #
    # This class is responsible for mapping RentalsUnited error codes and
    # descriptions.
    class Statuses
      class << self
        # Return error descriptions by error code
        #
        # Arguments
        #
        #   * +code+ [String] error code
        #
        # Usage
        #
        #   RentalsUnited::Dictionaries::Statuses.find("1")
        #   => "Property is not available for a given dates"
        #
        # Returns [String] error description
        def find(code)
          statuses_hash[code]
        end

        private
        def statuses_hash
          @statuses_hash ||= JSON.parse(File.read(file_path))
        end

        def file_path
          Hanami.root.join(
            "lib/concierge/suppliers/rentals_united/dictionaries",
            "statuses.json"
          ).to_s
        end
      end
    end
  end
end
