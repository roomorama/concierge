module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaImageSet+
    #
    # This class is responsible for building an array of images for the
    # property. 
    #
    # Array of images includes +Roomorama::Image+ objects
    class RoomoramaImageSet
      # Builds an array of property images
      #
      # Arguments:
      #
      #   * +image_hashes+ [Array] array with image hashes
      #
      # Returns +Array<Roomorama::Image>+ array of images
      def self.build(image_hashes)
        return [] unless image_hashes
        
        image_hashes.map do |h| 
          safe_hash = Concierge::SafeAccessHash.new(h)
          build_image(safe_hash)
        end
      end

      private
      def self.build_image(hash)
        url = hash.get("url")
        title = hash.get("content")
        identifier = Digest::MD5.hexdigest(url)

        image = Roomorama::Image.new(identifier)
        image.url = url
        image.caption = title
        image
      end
    end
  end
end
