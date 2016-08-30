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
        expect(image.caption).to eq(nil)
      end
    end

    it "returns empty array when no image_gallery attribute is there" do
      mapper = described_class.new([])
      images = mapper.build_images
      expect(images).to eq([])
    end

    context "when there is invalid URLs in images hash" do
      let(:image_hashes) do
        [
          {
              "category": "main",
              "content": "퇴실시간",
              "format": "jpg",
              "url": "http://image.wooripension.com/pension_images/w0209023/exterior_files/20108515249.8.1 169.jpg"
          },
          {
              "category": "ex",
              "content": "입실시간",
              "format": "jpg",
              "url": "http://image.wooripension.com/pension_images/w0104006/exterior_files/20107301818486.jpg"
          }
        ]
      end

      it "doesn't return images with spaces in URL" do
        mapper = described_class.new(image_hashes)
        images = mapper.build_images

        expect(images.size).to eq(1)
        expect(images).to all(be_kind_of(Roomorama::Image))

        image = images[0]
        expect(image.identifier).not_to be_nil
        expect(image.identifier).not_to eq("")
        expect(image.url).to eq(image_hashes[1][:url])
        expect(image.caption).to eq(nil)
      end
    end

    context "when there is image with non-ascii characters in URL" do
      let(:image_hashes) do
        [
          {
              "category": "main",
              "content": "퇴실시간",
              "format": "jpg",
              "url": "http://image.wooripension.com/pension_images/w0401046/etc/201391152213.남천계곡(국립공원안).jpg"
          }
        ]
      end

      it "URI-encodes given url" do
        mapper = described_class.new(image_hashes)
        images = mapper.build_images

        expect(images.size).to eq(1)
        expect(images).to all(be_kind_of(Roomorama::Image))

        image = images[0]
        expect(image.url).to eq('http://image.wooripension.com/pension_images/w0401046/etc/201391152213.%EB%82%A8%EC%B2%9C%EA%B3%84%EA%B3%A1(%EA%B5%AD%EB%A6%BD%EA%B3%B5%EC%9B%90%EC%95%88).jpg')
      end
    end
  end
end
