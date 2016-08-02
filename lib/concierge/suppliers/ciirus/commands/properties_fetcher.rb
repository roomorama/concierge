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

      OPERATION_NAME = :get_properties

      # mc_id [Fixnum] only properties of given management company will be returned,
      #                zero means all management companies
      def call(mc_id: 0)
        message = xml_builder.properties(management_company_id: mc_id)
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
        OPERATION_NAME
      end

      private

      def valid_property_detail?(result_hash)
        error_msg = result_hash.get('error_msg')
        error_msg.nil? || error_msg.empty?
      end

      def mapper
        @mapper ||= Ciirus::Mappers::Property.new
      end

      def build_properties(result_hash)
        properties = result_hash.get(
          'get_properties_response.get_properties_result.property_details'
        )
        result = []
        Array(properties).each do |property|
          property = to_safe_hash(property)
          result << mapper.build(property) if valid_property_detail?(property)
        end
        result
      end
    end
  end
end
