module SAW
  module Commands
    class Cancel < BaseFetcher
      def call(reference_number)
        payload = build_payload(reference_number)
        result = http.post(endpoint(:cancellation), payload, content_type)

        if result.success?
          result_hash = response_parser.to_hash(result.value.body)

          if valid_result?(result_hash)
            reference_number = result_hash.get("response.booking_ref_number")

            Result.new(reference_number)
          else
            error_result(result_hash)
          end
        else
          result
        end
      end

      private
      def build_payload(reference_number)
        payload_builder.build_cancel_request(reference_number)
      end
    end
  end
end
