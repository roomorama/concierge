module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::QuotationFetcher+
    #
    # This class is responsible for wrapping the logic related to making a
    # price quotation to RentalsUnited, parsing the response, and building the
    # +Quotation+ object with the data returned from their API.
    #
    # Usage
    #
    #   command = RentalsUnited::Commands::QuotationFetcher.new(
    #     credentials,
    #     quotation_params
    #   )
    #   result = command.call
    class QuotationFetcher < BaseFetcher
      attr_reader :quotation_params, :currency_code

      ROOT_TAG = "Pull_GetPropertyAvbPrice_RS"

      # Initialize +QuotationFetcher+ command.
      #
      # Arguments
      #
      #   * +credentials+
      #   * +quotation_params+ [Concierge::SafeAccessHash] stay parameters
      #   * +currency_code+ [String] currency code
      #
      # Stay parameters are defined by the set of attributes from
      # +API::Controllers::Params::MultiUnitQuote+ params object.
      #
      # +quotation_params+ object includes:
      #
      #   * +property_id+
      #   * +check_in+
      #   * +check_out+
      #   * +guests+
      def initialize(credentials, quotation_params, currency_code)
        super(credentials)
        @quotation_params = quotation_params
        @currency_code = currency_code
      end

      # Calls the RentalsUnited API method using the HTTP client.
      #
      # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
      # Returns a +Result+ with +Result::Error+ when operation fails
      def call
        payload = build_payload
        result = http.post(credentials.url, payload, headers)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(build_quotation(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def build_payload
        payload_builder.build_quotation_fetch_payload(
          property_id: quotation_params[:property_id],
          check_in:    quotation_params[:check_in],
          check_out:   quotation_params[:check_out],
          num_guests:  quotation_params[:guests]
        )
      end

      def build_quotation(result_hash)
        price = result_hash.get("#{ROOT_TAG}.PropertyPrices.PropertyPrice")

        mapper = Mappers::Quotation.new(quotation_params, price, currency_code)
        mapper.build_quotation
      end
    end
  end
end
