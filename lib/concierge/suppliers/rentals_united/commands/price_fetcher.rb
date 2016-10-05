module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::PriceFetcher+
    #
    # This class is responsible for wrapping the logic related to making a
    # price fetch to RentalsUnited, parsing the response, and building the
    # +Entities::Price with the data returned from their API.
    #
    # Usage
    #
    #   command = RentalsUnited::Commands::PriceFetcher.new(
    #     credentials,
    #     stay_params
    #   )
    #   result = command.call
    class PriceFetcher < BaseFetcher
      attr_reader :stay_params

      ROOT_TAG = "Pull_GetPropertyAvbPrice_RS"

      # Initialize +PriceFetcher+ command.
      #
      # Arguments
      #
      #   * +credentials+
      #   * +stay_params+ [Concierge::SafeAccessHash] stay parameters
      #
      # Stay parameters are defined by the set of attributes from
      # +API::Controllers::Params::MultiUnitQuote+ params object.
      #
      # +stay_params+ object includes:
      #
      #   * +property_id+
      #   * +check_in+
      #   * +check_out+
      #   * +guests+
      def initialize(credentials, stay_params)
        super(credentials)
        @stay_params = stay_params
      end

      # Calls the RentalsUnited API method using the HTTP client.
      #
      # Returns a +Result+ wrapping a +Entities::Price+ when operation succeeds
      # Returns a +Result+ with +Result::Error+ when operation fails
      def call
        payload = build_payload
        result = http.post(credentials.url, payload, headers)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(build_price(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def build_payload
        payload_builder.build_price_fetch_payload(
          property_id: stay_params[:property_id],
          check_in:    stay_params[:check_in],
          check_out:   stay_params[:check_out],
          num_guests:  stay_params[:guests]
        )
      end

      def build_price(result_hash)
        price = result_hash.get("#{ROOT_TAG}.PropertyPrices.PropertyPrice")

        mapper = Mappers::Price.new(price)
        mapper.build_price
      end
    end
  end
end
