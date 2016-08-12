require 'spec_helper'

RSpec.describe Kigo::Mappers::Resolver do

  describe '#images' do
    let(:image) {
      {
        'PHOTO_ID'        => '//supper-fantastic.url/hashed-identifier.jpg',
        'PHOTO_PANORAMIC' => false,
        'PHOTO_NAME'      => 'Balcony',
        'PHOTO_COMMENTS'  => 'Balcony with foosball table'
      }
    }

    it 'sets proper image data' do
      images = subject.images([image])

      expect(images.size).to eq 1
      image = images.first
      expect(image.url).to eq 'https://supper-fantastic.url/hashed-identifier.jpg'
      expect(image.identifier).to eq 'hashed-identifier.jpg'
      expect(image.caption).to eq 'Balcony with foosball table'
    end
  end

end