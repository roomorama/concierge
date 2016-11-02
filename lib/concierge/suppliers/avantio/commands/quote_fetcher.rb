module Avantio
  module Commands
    # +Avantio::Commands::QuoteFetcher+
    #
    # This class is responsible for wrapping the logic related to making a price
    # quotation to Avantio, parsing the response.
    # 
    # NOTE: Avantio GetBookingPrice method returns valid response even
    #       if accommodation is not available for given period, so it's important
    #       to check availability before using this fetcher.
    # Usage
    #
    #   command = Avantio::Commands::QuoteFetcher.new(credentials)
    #   result = command.call(params)
    #
    #   if result.success?
    #     result.value # Avantio::Entities::Quotation instance
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the instance of +Avantio::Entities::Quotation+.
    class QuoteFetcher

      OPERATION_NAME = :get_booking_price

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      def call(params)
        property_id = Avantio::PropertyId.from_roomorama_property_id(params[:property_id])
        message = xml_builder.booking_price(property_id, params[:guests], params[:check_in], params[:check_out])

        result = soap_client.call(OPERATION_NAME, message)
        return result unless result.success?

        result_hash = to_safe_hash(result.value)
        return error_result unless valid_result?(result_hash)

        quotation = mapper.build(result_hash)

        Result.new(quotation)
      end

      private

      def xml_builder
        @xml_builder ||= Avantio::XMLBuilder.new(credentials)
      end

      def mapper
        @mapper ||= Avantio::Mappers::Quotation.new
      end

      def soap_client
        @soap_client ||= Avantio::SoapClient.new
      end

      def valid_result?(result_hash)
        !!fetch_room_only_final(result_hash) &&
          !!fetch_currency(result_hash)
      end

      def fetch_room_only_final(result_hash)
        result_hash.get('get_booking_price_rs.booking_price.room_only_final')
      end

      def fetch_currency(result_hash)
        result_hash.get('get_booking_price_rs.booking_price.currency')
      end

      def to_safe_hash(hash)
        Concierge::SafeAccessHash.new(hash)
      end

      def error_result
        message = 'Unexpected `get_booking_price` response structure'
        mismatch(message, caller)
        Result.error(
          :unexpected_response_structure,
          message
        )
      end

      def mismatch(message, backtrace)
        response_mismatch = Concierge::Context::ResponseMismatch.new(
          message:   message,
          backtrace: backtrace
        )

        Concierge.context.augment(response_mismatch)
      end
    end
  end
end
