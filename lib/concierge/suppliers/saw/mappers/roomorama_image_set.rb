module SAW
  module Mappers
    # +SAW::Mappers::RoomoramaImageSet+
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
      #   * +hash+ [Concierge::SafeAccessHash] property hash with images
      #                                        information
      #   * +image_url_rewrite+ [Boolan] whether rewrite image URLs or not
      #
      # Returns [Array<Roomorama::Image] array of images
      def self.build(hash, image_url_rewrite)
        images = hash.get("image_gallery.image")
        
        return [] unless images
        
        to_array(images).map do |h| 
          safe_hash = Concierge::SafeAccessHash.new(h)
          build_image(safe_hash, image_url_rewrite)
        end
      end

      private
      def self.build_image(hash, image_url_rewrite)
        url = hash.get("large_image_url").to_s
        title = hash.get("title").to_s.strip

        identifier = hash.get("id") || Digest::MD5.hexdigest(url)
        image = Roomorama::Image.new(identifier)
        image.url = Converters::URLRewriter.build(url, rewrite: image_url_rewrite)
        image.caption = title
        image
      end
        
      def self.to_array(something)
        if something.is_a? Hash
          [something]
        else
          Array(something)
        end
      end
    end
  end
end
