module Ciirus
  module Commands
    #  +Ciirus::ImageListFetcher+
    #
    # This class is responsible for fetching a property image list
    # from Ciirus API, parsing the response and building the result.
    #
    # Usage
    #
    #   result = Ciirus::Commands::ImageListFetcher.new(credentials).fetch(params)
    #   if result.success?
    #     result.value
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the collection of image urls.
    class ImageListFetcher < BaseCommand

      def call(property_id)
        message = xml_builder.image_list(property_id)
        result = remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          image_list = build_image_list(result_hash)
          Result.new(image_list)
        else
          result
        end
      end

      protected

      def operation_name
        :get_image_list
      end

      private

      def build_image_list(result_hash)
        images = result_hash.get(
          'get_image_list_response.get_image_list_result.string'
        )
        Array(images)
      end
    end
  end
end
