module Ciirus
  module Commands
    # +Ciirus::Commands::QuoteFetcher+
    #
    # This class is responsible for wrapping the logic related to making a price
    # quotation to Ciirus, parsing the response, and building the +Quotation+ object
    # with the data returned from their API.
    #
    # Usage
    #
    #   command = Ciirus::Commands::QuoteFetcher.new(credentials)
    #   result = command.call(params)
    #
    #   if result.success?
    #     result.value # Quotation instance
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the +Quotation+.
    class QuoteFetcher < BaseCommand

      OPERATION_NAME = :get_properties
      EMPTY_ERROR_MESSAGE = 'No Properties were found that fit the specified search Criteria.'

      def call(params)
        arrive_date = convert_date(params[:check_in])
        depart_date = convert_date(params[:check_out])
        message = xml_builder.properties(property_id: params[:property_id],
                                         sleeps: params[:guests],
                                         quote: true,
                                         full_details: false,
                                         arrive_date: arrive_date,
                                         depart_date: depart_date)
        result = remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          if valid_result?(result_hash)
            quotation = mapper.build(params, result_hash)
            Result.new(quotation)
          else
            error_result(result_hash)
          end
        else
          result
        end
      end

      protected

      def operation_name
        OPERATION_NAME
      end

      private

      def valid_result?(result_hash)
        error_msg = result_hash.get('get_properties_response.get_properties_result.property_details.error_msg')
        # Special case for empty error message. In context of quotation it means
        # not available, so it's valid result.
        error_msg.nil? || error_msg.empty? || error_msg == EMPTY_ERROR_MESSAGE
      end

      def error_result(result_hash)
        error_msg = result_hash.get('get_properties_response.get_properties_result.property_details.error_msg')
        message = "The response contains not empty ErrorMsg: `#{error_msg}`"
        mismatch(message, caller)
        Result.error(:not_empty_error_msg, error_msg)
      end

      def mapper
        @mapper ||= Ciirus::Mappers::Quote.new
      end
    end
  end
end
