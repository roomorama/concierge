module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::ImageSet+
    #
    # This class is responsible for building an array of images for
    # properties and units.
    #
    # Array of images includes +Roomorama::Image+ objects
    class ImageSet
      attr_reader :raw_images

      # Rentals United image types mapping (image type id => name)
      # Names are used as captions for +Roomorama::Image+ objects
      IMAGE_TYPES = {
        "1" => "Main image",
        "2" => "Property plan",
        "3" => "Interior",
        "4" => "Exterior"
      }

      # Initialize +RentalsUnited::Mappers::ImageSet+ mapper
      #
      # Arguments:
      #
      #   * +raw_images+ [Array(Nori::StringWithAttributes)] array
      def initialize(raw_images)
        @raw_images = raw_images
      end

      # Builds an array of property images
      #
      # If image URL is not valid (contains a space sign) then image is not
      # included in the result array.
      #
      # Returns +Array<Roomorama::Image>+ array of images
      def build_images
        raw_images.map { |raw_image| build_image(raw_image) }
      end

      private
      def build_image(raw_image)
        url = URI.encode(raw_image.to_s)
        identifier = Digest::MD5.hexdigest(url)

        image = Roomorama::Image.new(identifier)
        image.url = url
        image.caption = IMAGE_TYPES[raw_image.attributes["ImageTypeID"]]

        image
      end
    end
  end
end
