require 'spec_helper'

module SAW
  RSpec.describe Mappers::RoomoramaImageSet do
    let(:hash) do
      safe_hash(
        "image_gallery"=>{
          "image"=> [
            {
              "title"=>"1 Bedroom Suite",
              "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=38990",
              "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=38992"
            },
            {
              "title"=>"1 Bedroom Suite",
              "thumbnail_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=38995",
              "large_image_url"=>"http://staging.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=38997"
            }
          ]
        }
      )
    end

    it "builds Roomorama::Image entity from hash" do
      images = described_class.build(hash, false) 
      
      photo = images.first

      expect(photo).to be_kind_of(Roomorama::Image)
      expect(photo.url).to eq(hash.get("image_gallery.image").first["large_image_url"])
      expect(photo.caption).to eq(hash.get("image_gallery.image").first["title"])
    end
    
    it "replaces SAW url" do
      images = described_class.build(hash, true) 
      
      photo = images.first

      expect(photo).to be_kind_of(Roomorama::Image)
      expect(photo.url).to eq(
        "http://www.servicedapartmentsworldwide.net/ImageHandler.jpg?ImageInstanceId=38992"
      )
    end

    it "returns empty array when no image_gallery attribute is there" do
      images = described_class.build(safe_hash({}), false) 
      expect(images).to eq([])
    end
    
    it "returns empty array when image_gallery is nil or empty" do
      images = described_class.build(safe_hash("image_gallery" => nil), false) 
      expect(images).to eq([])
      
      images = described_class.build(safe_hash("image_gallery" => {}), false) 
      expect(images).to eq([])
      
      images = described_class.build(safe_hash("image_gallery" => { "image" => []}), false) 
      expect(images).to eq([])
      
      images = described_class.build(safe_hash("image_gallery" => { "image" => nil}), false) 
      expect(images).to eq([])
    end

    private
    def safe_hash(hash)
      Concierge::SafeAccessHash.new(hash)
    end
    
  end
end
