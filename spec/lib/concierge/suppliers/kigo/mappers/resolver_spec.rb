require 'spec_helper'

RSpec.describe Kigo::Mappers::Resolver do

  describe '#images' do
    let(:property_id) { 123 }
    let(:image) {
      {
        'PHOTO_ID'        => '//supper-fantastic.url/hashed-identifier.jpg',
        'PHOTO_PANORAMIC' => false,
        'PHOTO_NAME'      => 'Balcony',
        'PHOTO_COMMENTS'  => 'Balcony with foosball table'
      }
    }

    it 'sets proper image data' do
      images = subject.images([image], property_id)

      expect(images.size).to eq 1
      image = images.first
      expect(image.url).to eq 'https://supper-fantastic.url/hashed-identifier.jpg'
      expect(image.identifier).to eq 'hashed-identifier.jpg'
      expect(image.caption).to eq 'Balcony with foosball table'
    end

    it 'skips caption if it blank' do
      image['PHOTO_COMMENTS'] = ' '
      images = subject.images([image], property_id)

      expect(images.first.caption).to be_nil
    end

    it 'creates a valid image if the URL contains non-Latin characters' do
      image['PHOTO_ID'] = '//dx577khz83dc.cloudfront.net/3304/P307_13_baño2_s.jpg'

      images = subject.images([image], property_id)
      expect(images.size).to eq 1

      image = images.first
      expect {
        image.validate!
      }.not_to raise_error
    end
  end

end
