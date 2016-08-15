require 'spec_helper'

RSpec.describe Ciirus::Commands::ImageListFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'example.org')
  end

  let(:property_id){ 38180 }

  let(:success_response) { read_fixture('ciirus/responses/image_list_response.xml') }
  let(:one_image_response) { read_fixture('ciirus/responses/one_image_list_response.xml') }
  let(:empty_response) { read_fixture('ciirus/responses/empty_image_list_response.xml') }
  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }
  subject { described_class.new(credentials) }

  describe '#call' do

    context 'when remote call internal error happened' do
      it 'returns result with error' do
        allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
        result = subject.call(property_id)

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
      end
    end

    context 'when many images' do
      let(:many_images) do
        [
          'http://images.ciirus.com/properties/25559/51502/images/ccpdemo1.jpg',
          'http://images.ciirus.com/properties/25559/51502/images/ccpdemo2.jpg',
          'http://images.ciirus.com/properties/25559/51502/images/ccpdemo3.jpg'
        ]
      end

      it 'returns array of images' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(property_id)
        images = result.value

        expect(result).to be_a Result
        expect(result).to be_success
        expect(images).to contain_exactly(*many_images)
      end
    end

    context 'when one image' do
      let(:one_image) do
        [
          'http://images.ciirus.com/properties/25559/51502/images/ccpdemo1.jpg'
        ]
      end

      it 'returns array with a image' do
        stub_call(method: described_class::OPERATION_NAME, response: one_image_response)

        result = subject.call(property_id)
        images = result.value

        expect(result).to be_a Result
        expect(result).to be_success
        expect(images).to contain_exactly(*one_image)
      end
    end

    it 'returns empty array for empty response' do
      stub_call(method: described_class::OPERATION_NAME, response: empty_response)

      result = subject.call(property_id)
      images = result.value

      expect(result).to be_a Result
      expect(result).to be_success
      expect(images).to be_empty
    end
  end
end