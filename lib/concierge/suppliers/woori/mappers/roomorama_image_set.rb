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
        image_hashes.map do |h|
          safe_hash = Concierge::SafeAccessHash.new(h)
          build_image(safe_hash) unless safe_hash.get("url").include?(" ")
        end.compact
      end

      private
      # Builds an image.
      #
      # Image captions are not set because all captions are given in Korean
      # language.
      #
      # Provided URLs contain non-ascii characters, so it's important to
      # URI.encode url before passing it to +Roomorama::Image+ validator
      #
      # Returns +Roomorama::Image+ image object
      def build_image(hash)
        url = URI.encode(hash.get("url").to_s)
        identifier = Digest::MD5.hexdigest(url)

        image = Roomorama::Image.new(identifier)
        image.url = url
        image
      end
    end
  end
end
