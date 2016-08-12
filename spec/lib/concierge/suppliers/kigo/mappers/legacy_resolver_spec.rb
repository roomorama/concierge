require 'spec_helper'

RSpec.describe Kigo::Mappers::LegacyResolver do

  describe '#images' do
    let(:image) {
      {
        'PHOTO_ID'        => '12345',
        'PHOTO_PANORAMIC' => false,
        'PHOTO_NAME'      => 'Balcony',
        'PHOTO_COMMENTS'  => 'Balcony with foosball table'
      }
    }

    it 'sets proper image data' do
      images = subject.images([image])

      expect(images.size).to eq 1
      image = images.first
      expect(image.url).to eq 'https://concierge-staging.roomorama.com/kigo/legacy/image/12345'
      expect(image.identifier).to eq '12345'
      expect(image.caption).to eq 'Balcony'
    end
  end

end