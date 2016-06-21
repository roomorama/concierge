module SAW
  module Mappers
    class RoomoramaImageSet
      def self.build(hash, image_url_rewrite)
        image_gallery = hash["image_gallery"]
        
        if image_gallery
          images = image_gallery['image']
          
          to_array(images).map { |h| build_image(h, image_url_rewrite) }
        else
          []
        end
      end

      def self.build_image(hash, image_url_rewrite)
        url = hash.fetch("large_image_url").to_s
        title = hash.fetch("title").to_s.strip

        identifier = hash["id"] || Digest::MD5.hexdigest(url)
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
