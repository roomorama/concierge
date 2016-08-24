require 'spec_helper'

module Woori
  RSpec.describe Mappers::RoomoramaImageSet do
    let(:image_hashes) do
      [
        {
            "category": "main",
            "content": "퇴실시간",
            "format": "jpg",
            "url": "http://image.wooripension.com/pension_images/w0104006/201652792223.jpg"
        },
        {
            "category": "ex",
            "content": "입실시간",
            "format": "jpg",
            "url": "http://image.wooripension.com/pension_images/w0104006/exterior_files/20107301818486.jpg"
        }
      ]
    end

    it "builds Roomorama::Image entities from array of hashes" do
      mapper = described_class.new(image_hashes)
      images = mapper.build_images

      expect(images.size).to eq(image_hashes.size)
      expect(images).to all(be_kind_of(Roomorama::Image))

      images.each_with_index do |image, index|
        hash = image_hashes[index]

        expect(image.identifier).not_to be_nil
        expect(image.identifier).not_to eq("")
        expect(image.url).to eq(hash[:url])
        expect(image.caption).to eq(hash[:content])
      end
    end

    it "returns empty array when no image_gallery attribute is there" do
      mapper = described_class.new([])
      images = mapper.build_images
      expect(images).to eq([])
    end
  end
end
