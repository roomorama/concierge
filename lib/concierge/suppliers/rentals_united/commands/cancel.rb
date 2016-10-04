module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::Cancel+
    #
    # This class is responsible for wrapping the logic related to cancellations
    # properties for RentalsUnited.
    class Cancel < BaseFetcher
      attr_reader :reference_number

      ROOT_TAG = "Push_CancelReservation_RS"

      # Initialize +Cancel+ command.
      #
      # Arguments
      #
      #   * +credentials+
      #   * +reference_number+ [String] id of reservation to cancel
      def initialize(credentials, reference_number)
        super(credentials)
        @reference_number = reference_number
      end

      # Cancels reservation by its id (reservation code)
      #
      # RentalsUnited API returns just simple success response, so by calling
      # `valid_status()` we actually checking whether cancellation is
      # successful or not.
      #
      # Returns a +Result+ wrapping a +reference_number+ of the cancelled
      # reservation when operation succeeds.
      # Returns a +Result+ with +Result::Error+ when operation fails
      def call
        payload = payload_builder.build_cancel_payload(reference_number)
        result = http.post(credentials.url, payload, headers)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(reference_number)
        else
          error_result(result_hash, ROOT_TAG)
        end
      end
    end
  end
end
