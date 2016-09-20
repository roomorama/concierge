module SAW
  module Commands
    # +SAW::Commands::BulkRatesFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # SAW property rates
    #
    # Usage
    #
    #   command = SAW::Commands::BulkRatesFetcher.new(credentials)
    #   result = command.call(property_id)
    class BulkRatesFetcher < BaseFetcher
      # How many days in future skip to fetch rates.
      STAY_OFFSET = 90

      # SAW returns rates for more properties if chosen STAY_LENGTH is 2 days
      STAY_LENGTH = 2

      # Calls the SAW API method using the HTTP client.
      #
      # Arguments
      #
      #   * +property_id+ [Array<String>] array of property ids
      #
      # The +call+ method returns a +Result+ object that, when successful, encapsulates the
      # resulting +Quotation+ object.
      def call(ids)
        payload = build_payload(ids)
        result = http.post(endpoint(:property_rates), payload, content_type)

        if result.success?
          result_hash = response_parser.to_hash(result.value.body)

          if valid_result?(result_hash)
            rates = build_rates(result_hash)

            Result.new(rates)
          else
            error_result(result_hash)
          end
        else
          result
        end
      end

      private
      def build_rates(rates_hash)
        rates_array = Array(rates_hash.get("response.property"))

        return rates_array unless rates_array.any?

        SAW::Mappers::UnitsPricing.build(rates_array, STAY_LENGTH)
      end

      def build_payload(ids)
        payload_builder.build_property_rate_request(
          ids:       ids.join(","),
          check_in:  check_in,
          check_out: check_out,
          guests:    1
        )
      end

      def check_in
        (today + STAY_OFFSET * one_day).strftime("%d/%m/%Y")
      end

      def check_out
        (today + (STAY_OFFSET+STAY_LENGTH) * one_day).strftime("%d/%m/%Y")
      end

      def one_day
        24 * 60 * 60
      end

      def today
        Time.now
      end
    end
  end
end
