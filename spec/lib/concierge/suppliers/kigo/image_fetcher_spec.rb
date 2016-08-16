require 'spec_helper'

RSpec.describe Kigo::ImageFetcher do

  describe '#fetch' do
    let(:params) {
      { property_id: 123, image_id: '123' }
    }
    let(:response) { 'base64-encoded-string' }
    let(:decoded_response) { Base64.decode64(response) }

    it 'saves image from decoded base64 response' do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_image) { Result.new(response) }

      result = subject.fetch(params)

      expect(result).to be_success
      expect(result.value).to be_a(StringIO)
    end

    it 'creates an error with failed request' do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_image) { Result.error(:connection_timeout) }
      result = nil

      expect { result = subject.fetch(params) }.to change { ExternalErrorRepository.count }

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end
  end


end