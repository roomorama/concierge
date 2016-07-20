module SAW
  module Commands
    class Cancel < BaseFetcher
      def call(reservation_id)
        payload = build_payload(reservation_id)
        result = http.post(endpoint(:cancellation), payload, content_type)

        if result.success?
          result_hash = response_parser.to_hash(result.value.body)

          if valid_result?(result_hash)
            reservation_id = result_hash.get("response.booking_ref_number")
            
            Result.new(reservation_id)
          else
            error_result(result_hash)
          end
        else
          result
        end
      end

      private
      def build_payload(reservation_id)
        payload_builder.build_cancel_request(reservation_id)
      end
    end
  end
end
