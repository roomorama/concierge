require 'spec_helper'

RSpec.describe Kigo::Mappers::LegacyResolver do

  describe '#images' do
    let(:property_id) { 123 }
    let(:image) {
      {
        'PHOTO_ID'        => '12345',
        'PHOTO_PANORAMIC' => false,
        'PHOTO_NAME'      => 'Balcony',
        'PHOTO_COMMENTS'  => 'Balcony with foosball table'
      }
    }

    it 'sets proper image data' do
      images = subject.images([image], property_id)

      expect(images.size).to eq 1
      image = images.first
      expect(image.url).to eq "#{ENV['CONCIERGE_URL']}/kigo/image/123/12345"
      expect(image.identifier).to eq '12345'
      expect(image.caption).to eq 'Balcony'
    end
  end

end