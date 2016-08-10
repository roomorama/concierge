require 'spec_helper'

RSpec.describe Ciirus::Commands::PropertiesFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://example.org')
  end

  let(:success_response) { read_fixture('ciirus/properties_response.xml') }
  let(:empty_response) { read_fixture('ciirus/empty_properties_response.xml') }
  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }

  subject { described_class.new(credentials) }

  before do
    # Replace remote call for wsdl with static wsdl
    allow(subject).to receive(:options).and_wrap_original do |m, *args|
      original = m.call
      original[:wsdl] = wsdl
      original
    end
  end

  describe '#call' do
    context 'when remote call internal error happened' do
      it 'returns result with error' do
        allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
        result = subject.call

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
      end
    end

    context 'when xml response is correct' do
      it 'returns success array of properties' do
        stub_call(method: :get_properties, response: success_response)

        result = subject.call

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to all(be_a Ciirus::Entities::Property)
      end

      it 'fills properties with right general attributes' do
        stub_call(method: :get_properties, response: success_response)

        result = subject.call

        property = result.value[0]
        expect(property.property_id).to eq('51502')
        expect(property.property_name).to eq('123 Fictional Lane')
        expect(property.address).to eq('Long Island 234')
        expect(property.zip).to eq('22313')
        expect(property.city).to eq('Omsk')
        expect(property.bedrooms).to eq(4)
        expect(property.sleeps).to eq(12)
        expect(property.min_nights_stay).to eq(1)
        expect(property.type).to eq('Unspecified')
        expect(property.country).to eq('Russia')
        expect(property.xco).to eq('0')
        expect(property.yco).to eq('0')
        expect(property.bathrooms).to eq(3.0)
        expect(property.king_beds).to eq(2)
        expect(property.queen_beds).to eq(1)
        expect(property.full_beds).to eq(0)
        expect(property.twin_beds).to eq(1)
        expect(property.extra_bed).to be(true)
        expect(property.sofa_bed).to be(false)
        expect(property.pets_allowed).to be(false)
        expect(property.currency_code).to eq('USD')
      end
      #
      # it 'fills properties with right amenities' do
      #   stub_call(method: :get_properties, response: success_response)
      #
      #   result = subject.call(params)
      #
      #   property = result.value[0]
      #   expect(property.property_id).to eq('51502')
      #   expect(property.property_name).to eq('123 Fictional Lane')
      #   expect(property.address).to eq('Long Island 234')
      #   expect(property.zip).to eq('22313')
      #   expect(property.city).to eq('Omks')
      #   expect(property.bedrooms).to eq(4)
      #   expect(property.sleeps).to eq(4)
      #   expect(property.min_nights_stay).to eq(1)
      #   expect(property.type).to eq('Unspecified')
      #   expect(property.country).to eq('Russia')
      #   expect(property.xco).to eq('0')
      #   expect(property.yco).to eq('0')
      #   expect(property.bathrooms).to eq(3.0)
      #   expect(property.king_beds).to eq(2)
      #   expect(property.queen_beds).to eq(1)
      #   expect(property.full_beds).to eq(0)
      #   expect(property.twin_beds).to eq(1)
      #   expect(property.extra_bed).to be(true)
      #   expect(property.sofa_bed).to be(false)
      #   expect(property.pets_allowed).to be(false)
      #   expect(property.currency_code).to eq('USD')
      #   expect(property.amenities).to eq()
      #
      # end

      it 'returns empty array for empty response' do
        stub_call(method: :get_properties, response: empty_response)

        result = subject.call

        properties = result.value
        expect(properties).to be_empty
      end
    end

    # context 'when xml contains error message' do
    #   it 'returns a result with error' do
    #     stub_call(method: :get_properties, response: error_response)
    #
    #     result = subject.call(params)
    #
    #     expect(result.success?).to be false
    #     expect(result.error.code).to eq(:not_empty_error_msg)
    #   end
    # end
  end
end