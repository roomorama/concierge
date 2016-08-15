require 'spec_helper'

RSpec.describe Kigo::ImageFetcher do

  let(:image_path) { './some/path'}
  subject { described_class.new(image_path) }

  describe '#fetch' do
    let(:property_id) { 1 }
    let(:identifier) { 'hashed-string' }
    let(:response) { 'base64-encoded-string' }
    let(:decoded_response) { Base64.decode64(response) }

    it 'saves image from decoded base64 response' do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_image) { Result.new(response) }

      file = double('file')
      image_url = [image_path, "#{identifier}.jpg"]
      expect(File).to receive(:open).with(image_url, 'w').and_yield(file)
      expect(file).to receive(:write).with(decoded_response)
      subject.fetch(property_id, identifier)

      expect(subject.path).to eq image_path
    end
  end


end