module Ciirus
  module Commands
    #  +Ciirus::Commans::PropertyRatesFetcher+
    #
    # This class is responsible for fetching property rates
    # from Ciirus API, parsing the response and building the result.
    #
    # Usage
    #
    #   result = Ciirus::Commands::PropertyRatesFetcher.new(credentials).fetch(property_id)
    #   if result.success?
    #     result.value
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the collection of +PropertyRate+.
    class PropertyRatesFetcher < BaseCommand

      OPERATION_NAME = :get_property_rates

      def call(property_id)
        message = xml_builder.property_rates(property_id)
        result = remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          property_rates = build_property_rates(result_hash)
          Result.new(property_rates)
        else
          result
        end
      end

      protected

      def operation_name
        OPERATION_NAME
      end

      private

      def mapper
        @mapper ||= Ciirus::Mappers::PropertyRate.new
      end

      def build_property_rates(rates_hash)
        rates = rates_hash.get(
          'get_property_rates_response.get_property_rates_result.rate'
        )

        Array(rates).map { |rate| mapper.build(rate) }
      end
    end
  end
end
