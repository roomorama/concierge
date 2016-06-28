module SAW
  module Commands
    # +SAW::Price+
    #
    # This class is responsible for wrapping the logic related to making a price
    # quotation to SAW, parsing the response, and building the +Quotation+ object
    # with the data returned from their API.
    #
    # Usage
    #
    #   result = SAW::Price.new(credentials).quote(stay_params)
    #   if result.success?
    #     process_quotation(result.value)
    #   else
    #     handle_error(result.error)
    #   end
    #
    # The +quote+ method returns a +Result+ object that, when successful, encapsulates the
    # resulting +Quotation+ object.
    class PriceFetcher < BaseFetcher
      # Calls the SAW API method using the HTTP client.
      # Returns a +Result+ object.
      def call(params)
        payload = build_payload(params)
        result = http.post(endpoint(:property_rates), payload, content_type)

        if result.success?
          result_hash = response_parser.to_hash(result.value.body)

          if valid_result?(result_hash)
            property_rate = SAW::Mappers::PropertyRate.build(result_hash)
            quotation = SAW::Mappers::Quotation.build(params, property_rate)
          
            Result.new(quotation)
          else
            error_result(result_hash)
          end
        else
          result
        end
      end

      private
      def build_payload(params)
        payload_builder.build_compute_pricing(
          property_id:   params[:property_id],
          unit_id:       params[:unit_id],
          check_in:      params[:check_in],
          check_out:     params[:check_out],
          num_guests:    params[:guests]
        )
      end
    end
  end
end
