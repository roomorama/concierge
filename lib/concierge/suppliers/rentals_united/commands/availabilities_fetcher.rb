require_relative 'base_fetcher'

module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::AvailabilitiesFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # property availabilities from RentalsUnited
    class AvailabilitiesFetcher < BaseFetcher
      attr_reader :property_id

      ROOT_TAG = "Pull_ListPropertyAvailabilityCalendar_RS"
      YEARS_COUNT_TO_FETCH = 1

      # Initialize +AvailabilitiesFetcher+ command.
      #
      # Arguments
      #
      #   * +credentials+
      #   * +property_id+ [String]
      #
      # Usage:
      #
      #   RentalsUnited::Commands::AvailabilitiesFetcher.new(
      #     credentials,
      #     property_id
      #   )
      def initialize(credentials, property_id)
        super(credentials)

        @property_id = property_id
      end

      # Retrieves property availabilities.
      #
      # Returns a +Result+ wrapping +Array+ of +Entities::Availability+
      # Returns a +Result+ with +Result::Error+ when operation fails
      def fetch_availabilities
        payload = payload_builder.build_availabilities_fetch_payload(
          property_id,
          date_from,
          date_to
        )
        result = http.post(credentials.url, payload, headers)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(build_availabilities(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def date_from
        Time.now.strftime("%Y-%m-%d")
      end

      def date_to
        current = Time.now

        year = current.year + YEARS_COUNT_TO_FETCH
        date = Time.new(year, current.month, current.day)
        date.strftime("%Y-%m-%d")
      end

      def build_availabilities(hash)
        days = Array(hash.get("#{ROOT_TAG}.PropertyCalendar.CalDay"))
        days.map do |day|
          mapper = Mappers::Availability.new(day)
          mapper.build_availability
        end
      end
    end
  end
end
