module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::OwnerFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # owner from RentalsUnited
    class OwnerFetcher < BaseFetcher
      ROOT_TAG = "Pull_GetOwnerDetails_RS"

      attr_reader :owner_id

      # Initialize +OwnerFetcher+ command.
      #
      # Arguments
      #
      #   * +credentials+
      #   * +owner_id+ [String]
      #
      # Usage:
      #
      #   RentalsUnited::Commands::OwnerFetcher.new(credentials, owner_id)
      def initialize(credentials, owner_id)
        super(credentials)

        @owner_id = owner_id
      end

      # Retrieves owner.
      #
      # Returns a +Result+ wrapping +Entities::Owner+
      # Returns a +Result+ with +Result::Error+ when operation fails
      def fetch_owner
        payload = payload_builder.build_owner_fetch_payload(owner_id)
        result = api_call(payload)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(build_owner(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def build_owner(hash)
        owner_hash = hash.get("#{ROOT_TAG}.Owner")

        if owner_hash
          mapper = RentalsUnited::Mappers::Owner.new(owner_hash)
          mapper.build_owner
        else
          desc = "Unknown owner with id `#{owner_id}`"
          Result.error(:owner_not_found, desc)
        end
      end
    end
  end
end
