module RentalsUnited
  module Dictionaries
    class Statuses
      class << self
        def find(id)
          statuses_hash[id]
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
