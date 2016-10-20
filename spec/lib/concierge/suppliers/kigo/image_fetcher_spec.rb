require 'spec_helper'

RSpec.describe Kigo::ImageFetcher do

  subject { described_class.new(property_id, image_id) }

  describe '#fetch' do
    let(:property_id) { 1 }
    let(:image_id) { 'hashed-string' }
    let(:response) { 'base64-encoded-string' }

    it 'saves image from decoded base64 response' do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_image) { Result.new(response) }

      result = subject.fetch

      expect(result).to be_success
      expect(result.value).to be_a(StringIO)
    end

    it 'creates an error with failed request' do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_image) { Result.error(:connection_timeout) }
      result = subject.fetch

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
      expect(result.error.data).to be_nil
    end
  end


end
