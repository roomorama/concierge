module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::PropertyIdsFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # property ids from RentalsUnited, parsing the response, and building
    # +Result+ object.
    class PropertyIdsFetcher < BaseFetcher
      attr_reader :location_id

      ROOT_TAG = "Pull_ListProp_RS"

      # Initialize +PropertyIdsFetcher+ command.
      #
      # Arguments
      #
      #   * +credentials+
      #   * +location_id+
      #
      # Usage:
      #
      #   RentalsUnited::Commands::PropertyIdsFetcher.new(
      #     credentials,
      #     location_id
      #   )
      def initialize(credentials, location_id)
        super(credentials)

        @location_id = location_id
      end

      # Retrieves property ids
      #
      # IDs of properties which are no longer available will be filtered out.
      #
      # Returns a +Result+ wrapping +Array+ of +String+ property ids
      # Returns a +Result+ with +Result::Error+ when operation fails
      def fetch_property_ids
        payload = payload_builder.build_property_ids_fetch_payload(location_id)
        result = http.post(credentials.url, payload, headers)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(build_property_ids(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def build_property_ids(hash)
        properties = hash.get("#{ROOT_TAG}.Properties.Property")
        return [] unless properties

        Array(properties).map { |property| property["ID"] }
      end
    end
  end
end
