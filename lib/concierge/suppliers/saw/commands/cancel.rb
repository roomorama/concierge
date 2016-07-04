module SAW
  module Commands
    class Cancel < BaseFetcher
      def call(params)
        payload = build_payload(params)
        result = http.post(endpoint(:property_booking), payload, content_type)

        if result.success?
          result_hash = response_parser.to_hash(result.value.body)

          if valid_result?(result_hash)
            reservation = SAW::Mappers::Reservation.build(params, result_hash)
            
            Result.new(reservation)
          else
            error_result(result_hash)
          end
        else
          result
        end
      end

      private
      def build_payload(params)
        payload_builder.build_cancel_request(params[:reservation_id])
      end
    end
  end
end
