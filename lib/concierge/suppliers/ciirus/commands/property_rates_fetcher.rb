module Ciirus
  module Commands
    #  +Ciirus::PropertyRatesFetcher+
    #
    # This class is responsible for fetching property rates
    # from Ciirus API, parsing the response and building the result.
    #
    # Usage
    #
    #   result = Ciirus::Commands::PropertyRatesFetcher.new(credentials).fetch(params)
    #   if result.success?
    #     result.value
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the collection of +PropertyRate+.
    class PropertyRatesFetcher < BaseCommand

      def call(params)
        message = xml_builder.property_rates(params[:property_id])
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
        :get_property_rates
      end

      private

      def build_property_rates(rates_hash)
        rates = rates_hash.get(
            'get_property_rates_response.get_property_rates_result.rate'
        )
        if rates
          Array(rates).map do |rate|
            Ciirus::Mappers::PropertyRate.build(rate)
          end
        else
          []
        end
      end
    end
  end
end
