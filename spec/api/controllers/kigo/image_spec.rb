require 'spec_helper'

RSpec.describe API::Controllers::Kigo::Image do
  include Support::HTTPStubbing
  include Support::Factories

  let!(:supplier) { create_supplier(name: 'KigoLegacy') }
  let!(:host)     { create_host(supplier_id: supplier.id) }
  let!(:property) { create_property(identifier: '123', host_id: host.id) }

  describe '#call' do

    let(:params) {
      { property_id: '123', image_id: 'hashed_identifier' }
    }

    [:property_id, :image_id].each do |key|
      it "returns 404 without #{key}" do
        params.delete(key)
        response = parse_response(subject.call(params))

        expect(response.status).to eq 404
      end

    end

    it 'returns 404 if property does not exist' do
      params[:property_id] = 'unknown'

      response = parse_response(subject.call(params))

      expect(response.status).to eq 404
    end

    it 'fails with external error' do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch) { Result.error(:connection_timeout) }

      response = parse_response(subject.call(params))

      expect(response.status).to eq 503
      expect(response.body['errors']).to eq 'connection_timeout'

      external_error = ExternalErrorRepository.last

      expect(external_error.code).to eq 'connection_timeout'
      expect(external_error.supplier).to eq 'KigoLegacy'
      expect(external_error.operation).to eq 'image'
    end

    it 'returns image' do
      decoded_image_string = StringIO.new('huge string')
      expected_headers     = { 'Content-Type' => 'image/jpeg' }

      allow_any_instance_of(Kigo::ImageFetcher).to receive(:fetch) { Result.new(decoded_image_string) }

      response = subject.call(params)

      expect(response[0]).to eq 200
      expect(response[1]).to eq expected_headers
      expect(response[2]).to eq decoded_image_string
    end
  end
end