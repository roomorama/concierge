module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::PropertyFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # property from RentalsUnited, parsing the response, and building
    # +Result+ object.
    class PropertyFetcher < BaseFetcher
      attr_reader :property_id, :location

      ROOT_TAG = "Pull_ListSpecProp_RS"

      # Initialize +PropertyFetcher+ command.
      #
      # Arguments
      #
      #   * +credentials+
      #   * +property_id+ [String]
      #   * +location+ [Entities::Location]
      #
      # Usage:
      #
      #   RentalsUnited::Commands::PropertyFetcher.new(
      #     credentials,
      #     property_id,
      #     location
      #   )
      def initialize(credentials, property_id, location)
        super(credentials)

        @property_id = property_id
        @location = location
      end

      def fetch_property
        payload = payload_builder.build_property_fetch_payload(property_id)
        result = http.post(credentials.url, payload, headers)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(build_property(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def build_property(hash)
        property = hash.get("#{ROOT_TAG}.Property")
        return error_result(hash, ROOT_TAG) unless property

        mapper = RentalsUnited::Mappers::Property.new(property, location)
        mapper.build_property
      end
    end
  end
end
