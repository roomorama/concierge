module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::OwnersFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # owners from RentalsUnited
    class OwnersFetcher < BaseFetcher
      ROOT_TAG = "Pull_ListAllOwners_RS"

      # Retrieves owners.
      #
      # Returns a +Result+ wrapping +Array+ of +Entities::Owner+
      # Returns a +Result+ with +Result::Error+ when operation fails
      def fetch_owners
        payload = payload_builder.build_owners_fetch_payload
        result = api_call(payload)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(build_owners(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def build_owners(hash)
        owners = hash.get("#{ROOT_TAG}.Owners.Owner")

        Array(owners).map do |owner_hash|
          safe_hash = Concierge::SafeAccessHash.new(owner_hash)
          mapper = RentalsUnited::Mappers::Owner.new(safe_hash)
          mapper.build_owner
        end
      end
    end
  end
end
