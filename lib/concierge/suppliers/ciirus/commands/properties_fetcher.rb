module Ciirus
  module Commands
    # +Ciirus::Commands::PropertiesFetcher+
    #
    # This class is responsible for wrapping the logic related to getting all
    # properties from Ciirus, parsing the response, and building the +Result+ object
    # with the data returned from their API.
    #
    # Usage
    #
    #   command = Ciirus::Commands::PropertiesFetcher.new(credentials)
    #   result = command.call(params)
    #
    #   if result.success?
    #     result.value # Array of Property instance
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the array of +Ciirus::Entities::Property+.
    class PropertiesFetcher < BaseCommand

      def call
        filter_options = Ciirus::FilterOptions.new
        search_options = Ciirus::SearchOptions.new
        special_options = Ciirus::SpecialOptions.new
        # Send empty arrive_date and depart_date to get all properties
        message = xml_builder.properties(filter_options, search_options,
                                         special_options, '', '')
        result = remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          properties = build_properties(result_hash)
          Result.new(properties)
        else
          result
        end
      end

      protected

      def operation_name
        :get_properties
      end

      private

      def build_properties(result_hash)
        properties = result_hash.get(
          'get_properties_response.get_properties_result.property_details'
        )
        if properties
          Array(properties).map do |property|
            # TODO: validate property_details and filter invalid
            Ciirus::Mappers::Property.build(property)
          end
        else
          []
        end
      end
    end
  end
end
