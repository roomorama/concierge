module Ciirus
  module Commands
    #  +Ciirus::PropertyAvailableFetcher+
    #
    # This class is responsible for fetching property availability
    # from Ciirus API and parsing the response.
    #
    # Usage
    #
    #   result = Ciirus::Commands::PropertyAvailableFetcher.new(credentials).fetch(params)
    #   if result.success?
    #     result.value  # => true/false
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the boolean result.
    class PropertyAvailableFetcher < BaseCommand

      def call(params)
        check_in = convert_date(params[:check_in])
        check_out = convert_date(params[:check_out])
        message = xml_builder.is_property_available(params[:property_id],
                                                    check_in,
                                                    check_out)
        result = remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          property_rate = Ciirus::Mappers::PropertyAvailable.build(result_hash)
          Result.new(property_rate)
        else
          result
        end
      end

      protected

      def operation_name
        :is_property_available
      end
    end
  end
end
