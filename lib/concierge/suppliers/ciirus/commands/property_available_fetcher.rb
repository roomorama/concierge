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
    # The +fetch+ method returns a +Result+ object that, when successful,
    # encapsulates the boolean result.
    class PropertyAvailableFetcher < BaseCommand

      def call(params)
        message = xml_builder.is_property_available(params[:property_id],
                                                    params[:check_in],
                                                    params[:check_out])
        result = remote_call(message)
        if result.success?
          result_hash = response_parser.to_hash(result.value)
          if valid_result?(result_hash)
            property_rate = Ciirus::Mappers::PropertyAvailable.build(result_hash)
            Result.new(property_rate)
          else
            error_result(result_hash)
          end
        end
      end

      protected

      def operation_name
        :IsPropertyAvailable
      end
    end
  end
end
