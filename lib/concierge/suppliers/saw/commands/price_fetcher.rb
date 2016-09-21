module SAW
  module Commands
    # +SAW::Commands::PriceFetcher+
    #
    # This class is responsible for wrapping the logic related to making a price
    # quotation to SAW, parsing the response, and building the +Quotation+ object
    # with the data returned from their API.
    #
    # Usage
    #
    #   command = SAW::Commands::PriceFetcher.new(credentials)
    #   result = command.call(stay_params)
    #
    #   if result.success?
    #     process_quotation(result.value)
    #   else
    #     handle_error(result.error)
    #   end
    class PriceFetcher < BaseFetcher
      # Calls the SAW API method using the HTTP client.
      #
      # Arguments
      #
      #   * +params+ [Concierge::SafeAccessHash] stay parameters
      #
      # Stay parameters are defined by the set of attributes from
      # +API::Controllers::Params::MultiUnitQuote+ params object.
      #
      # +params+ object includes:
      #
      #   * +property_id+
      #   * +unit_id+
      #   * +check_in+
      #   * +check_out+
      #   * +guests+
      #
      # The +call+ method returns a +Result+ object that, when successful, encapsulates the
      # resulting +Quotation+ object.
      def call(params)
        payload = build_payload(params)
        result = http.post(endpoint(:property_rates), payload, content_type)

        if result.success?
          result_hash = response_parser.to_hash(result.value.body)

          if valid_result?(result_hash)
            quotation = build_quotation(params, result_hash)

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
          property_id: params[:property_id],
          unit_id:     params[:unit_id],
          check_in:    params[:check_in],
          check_out:   params[:check_out],
          num_guests:  params[:guests]
        )
      end

      def build_quotation(params, result_hash)
        rates_hash = result_hash.get("response.property")
        safe_hash  = Concierge::SafeAccessHash.new(rates_hash)

        SAW::Mappers::Quotation.build(params, safe_hash)
      end
    end
  end
end
