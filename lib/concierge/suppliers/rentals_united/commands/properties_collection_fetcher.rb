module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::PropertiesCollectionFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # properties collection for a given owner from RentalsUnited
    class PropertiesCollectionFetcher < BaseFetcher
      ROOT_TAG = "Pull_ListOwnerProp_RS"

      attr_reader :owner_id

      # Initialize +PropertiesCollectionFetcher+ command.
      #
      # Arguments
      #
      #   * +credentials+
      #   * +owner_id+ [String]
      #
      # Usage:
      #
      #   RentalsUnited::Commands::PropertiesCollectionFetcher.new(
      #     credentials,
      #     owner_id
      #   )
      def initialize(credentials, owner_id)
        super(credentials)

        @owner_id = owner_id
      end

      # Retrieves properties collection.
      #
      # Returns a +Result+ wrapping +Entities::PropertiesCollection+
      # Returns a +Result+ with +Result::Error+ when operation fails
      def fetch_properties_collection_for_owner
        payload = payload_builder.build_properties_collection_fetch_payload(
          owner_id
        )
        result = api_call(payload)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(build_properties_collection(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def build_properties_collection(hash)
        properties = Array(hash.get("#{ROOT_TAG}.Properties.Property"))

        mapper = RentalsUnited::Mappers::PropertiesCollection.new(properties)
        mapper.build_properties_collection
      end
    end
  end
end
