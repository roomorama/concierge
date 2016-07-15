module Ciirus
  module Commands
    #  +Ciirus::DescriptionsPlainTextFetcher+
    #
    # This class is responsible for fetching a property description plain text
    # from Ciirus API, parsing the response and building the result.
    #
    # Usage
    #
    #   result = Ciirus::Commands::DescriptionsPlainTextFetcher.new(credentials).fetch(params)
    #   if result.success?
    #     result.value # description string
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the description string.
    class DescriptionsPlainTextFetcher < BaseCommand

      OPERATION_NAME = :get_descriptions_plain_text

      # Response contains the text if a property doesn't have plain text description
      EMPTY_DESCRIPTION_MESSAGE = 'GetDescriptionsPlainText: Error - The description is blank'

      def call(property_id)
        message = xml_builder.descriptions(property_id)
        result = remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          description = fetch_description(result_hash)
          Result.new(description)
        else
          result
        end
      end

      protected

      def operation_name
        OPERATION_NAME
      end

      private

      def fetch_description(result_hash)
        description = result_hash.get(
          'get_descriptions_plain_text_response.get_descriptions_plain_text_result'
        ).to_s
        is_empty?(description) ? '' : description
      end

      def is_empty?(description)
        description == EMPTY_DESCRIPTION_MESSAGE
      end
    end
  end
end
