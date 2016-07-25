module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaImageSet+
    #
    # This class is responsible for building an array of images for the
    # property. 
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
      # Returns +Array<Roomorama::Image>+ array of images
      def build_images
        return [] unless image_hashes
        
        image_hashes.map do |h| 
          safe_hash = Concierge::SafeAccessHash.new(h)
          build_image(safe_hash)
        end
      end

      private
      def build_image(hash)
        url, title, identifier = fetch_image_data(hash)

        image = Roomorama::Image.new(identifier)
        image.url = url
        image.caption = title
        image
      end

      def fetch_image_data(hash)
        url = hash.get("url")
        title = hash.get("content")
        identifier = Digest::MD5.hexdigest(url)

        [url, title, identifier]
      end
    end
  end
end
