require 'spec_helper'

RSpec.describe Ciirus::Commands::PropertyRatesFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'example.org')
  end

  let(:property_id) { 38180 }

  let(:success_response) { read_fixture('ciirus/responses/property_rates_response.xml') }
  let(:one_rate_response) { read_fixture('ciirus/responses/one_property_rate_response.xml') }
  let(:empty_response) { read_fixture('ciirus/responses/empty_property_rates_response.xml') }
  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }
  subject { described_class.new(credentials) }

  describe '#call' do
    let(:many_rates) do
       [
         Ciirus::Entities::PropertyRate.new(
           DateTime.new(2014, 6, 27),
           DateTime.new(2014, 8, 22),
           3,
           157.50
         ),
         Ciirus::Entities::PropertyRate.new(
           DateTime.new(2014, 8, 23),
           DateTime.new(2014, 10, 16),
           3,
           141.43
         )
       ]
    end

    let(:one_rate) do
      [
        Ciirus::Entities::PropertyRate.new(
          DateTime.new(2014, 6, 27),
          DateTime.new(2014, 8, 22),
          3,
          157.50
        )
      ]
    end

    context 'when remote call internal error happened' do
      it 'returns result with error' do
        allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
        result = subject.call(property_id)

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
        expect(result.error.data).to be_nil
      end
    end

    context 'when many rates' do
      it 'returns array of rates' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(property_id)
        rates = result.value

        expect(result).to be_a Result
        expect(result).to be_success
        expect(rates).to eq(many_rates)
      end
    end

    context 'when one rate' do
      it 'returns array with a rate' do
        stub_call(method: described_class::OPERATION_NAME, response: one_rate_response)

        result = subject.call(property_id)
        rates = result.value

        expect(result).to be_a Result
        expect(result).to be_success
        expect(rates).to eq(one_rate)
      end
    end

    it 'returns empty array for empty response' do
      stub_call(method: described_class::OPERATION_NAME, response: empty_response)

      result = subject.call(property_id)
      rates = result.value

      expect(result).to be_a Result
      expect(result).to be_success
      expect(rates).to be_empty
    end
  end
end
