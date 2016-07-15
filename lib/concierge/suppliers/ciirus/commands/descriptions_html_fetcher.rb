module Ciirus
  module Commands
    #  +Ciirus::DescriptionsHtmlFetcher+
    #
    # This class is responsible for fetching a property html description
    # from Ciirus API, parsing the response, sanitize and building the result. The fetcher is useful
    # as well as not all properties have plain text descriptions, in this case try to get
    # html descriptions.
    #
    # Usage
    #
    #   result = Ciirus::Commands::DescriptionsHtmlFetcher.new(credentials).fetch(property_id)
    #   if result.success?
    #     result.value # description string
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the description string.
    class DescriptionsHtmlFetcher < BaseCommand

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
        :get_descriptions_html
      end

      private

      def fetch_description(result_hash)
        html = result_hash.get(
          'get_descriptions_html_response.get_descriptions_html_result'
        )
        Sanitize.clean(html, elements: ['p', 'br', 'strong', 'em'], remove_contents: ['script', 'style','img'])
          .split(/\n|<br>|<\/br>|<p>|<\/p>/)
          .select{ |x| x.size > 100 }
          .join('<br><br>')
      end
    end
  end
end
