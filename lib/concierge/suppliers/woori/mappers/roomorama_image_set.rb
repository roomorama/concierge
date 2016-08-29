module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaImageSet+
    #
    # This class is responsible for building an array of images for
    # properties and units.
    #
    # Array of images includes +Roomorama::Image+ objects
    class RoomoramaImageSet
      attr_reader :image_hashes

      # Initialize RoomoramaImageSet mapper
      #
      # Arguments:
      #
      #   * +image_hashes+ [Array] array with image hashes
      def initialize(image_hashes)
        @image_hashes = image_hashes
      end

      # Builds an array of property images
      #
      # If image URL is not valid (contains a space sign) then image is not
      # included in the result array.
      #
      # Returns +Array<Roomorama::Image>+ array of images
      def build_images
        all_images = image_hashes.map do |h|
          safe_hash = Concierge::SafeAccessHash.new(h)
          build_image(safe_hash)
        end

        filter_images_with_only_valid_urls(all_images)
      end

      private
      # Image captions are not set because all captions in Korean language
      def build_image(hash)
        url, identifier = fetch_image_data(hash)

        image = Roomorama::Image.new(identifier)
        image.url = url
        image
      end

      def fetch_image_data(hash)
        url = hash.get("url")
        identifier = Digest::MD5.hexdigest(url)

        [url, identifier]
      end

      def filter_images_with_only_valid_urls(images)
        images.reject { |image| image.url.include?(" ") }
      end
    end
  end
end
