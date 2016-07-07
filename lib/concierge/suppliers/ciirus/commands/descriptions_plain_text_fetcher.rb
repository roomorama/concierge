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

      def call(property_id)
        message = xml_builder.descriptions_plain_text(property_id)
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
        :get_descriptions_plain_text
      end

      private

      def fetch_description(result_hash)
        result_hash.get(
          'get_descriptions_plain_text_response.get_descriptions_plain_text_result'
        ).to_s
      end
    end
  end
end
