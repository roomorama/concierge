module Woori
  module Commands
    # +Woori::Commands::QuotationFetcher+
    #
    # This class is responsible for wrapping the logic related to making a
    # price quotation to Woori, parsing the response, and building the 
    # +Quotation+ object with the data returned from their API.
    #
    # Usage
    #
    #   command = Woori::Commands::QuotationFetcher.new(credentials)
    #   result = command.call(stay_params)
    #
    #   if result.success?
    #     process_quotation(result.value)
    #   else
    #     handle_error(result.error)
    #   end
    class QuotationFetcher < BaseFetcher
      include Concierge::JSON
    
      ENDPOINT = "available"
      MAXIMUM_STAY_LENGTH = 30

      # Calls the Woori API method using the HTTP client.
      # 
      # Arguments
      #
      #   * +params+ [Concierge::SafeAccessHash] stay parameters
      # 
      # Stay parameters are defined by the set of attributes from
      # +API::Controllers::Params::MultiUnitQuote+ params object.
      #
      # +quotation_params+ object includes:
      #
      #   * +property_id+ 
      #   * +unit_id+ 
      #   * +check_in+
      #   * +check_out+
      #   * +guests+
      #
      # The +call+ method returns a +Result+ object that, when successful,
      # encapsulates the resulting +Quotation+ object.
      def call(quotation_params)
        return unavailable_quotation(quotation_params) if stay_too_long?(quotation_params)

        params = build_request_params(quotation_params)
        result = http.get(ENDPOINT, params, headers)

        if result.success?
          decoded_result = json_decode(result.value.body)
          
          if decoded_result.success?
            safe_hash = Concierge::SafeAccessHash.new(decoded_result.value)
            quotation = Woori::Mappers::Quotation.new(quotation_params, safe_hash).build
            Result.new(quotation)
          else
            decoded_result
          end
        else
          result
        end
      end

      private
      def build_request_params(params)
        {
          roomCode:        params[:unit_id],
          searchStartDate: params[:check_in],
          searchEndDate:   params[:check_out]
        }
      end

      def stay_too_long?(quotation_params)
        quotation_params.stay_length > MAXIMUM_STAY_LENGTH
      end

      def unavailable_quotation(params)
        quotation = ::Quotation.new(
          property_id: params[:property_id],
          unit_id:     params[:unit_id],
          check_in:    params[:check_in].to_s,
          check_out:   params[:check_out].to_s,
          guests:      params[:guests],
          available:   false
        )

        Result.new(quotation)
      end
    end
  end
end