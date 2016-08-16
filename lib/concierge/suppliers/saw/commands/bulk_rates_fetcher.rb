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
        rates = rates_hash.get("response.property")

        return [] unless rates

        Array(rates).map do |rate|
          safe_hash = Concierge::SafeAccessHash.new(rate)
          SAW::Mappers::PropertyRate.build(safe_hash)
        end
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
        (today + 30 * one_day).strftime("%d/%m/%Y")
      end

      def check_out
        (today + 31 * one_day).strftime("%d/%m/%Y")
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
