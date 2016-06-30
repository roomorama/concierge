require 'spec_helper'
require 'savon/mock/spec_helper'

RSpec.describe Ciirus::Commands::PropertyRatesFetcher do
  include Support::Fixtures
  include Savon::SpecHelper

  before { savon.mock! }
  after { savon.unmock! }

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'example.org')
  end

  let(:params) do
    {
      property_id: 38180
    }
  end

  let(:success_response) { read_fixture('ciirus/property_rates_response.xml') }
  let(:one_rate_response) { read_fixture('ciirus/one_property_rate_response.xml') }
  let(:empty_response) { read_fixture('ciirus/empty_property_rates_response.xml') }
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

    context 'when many rates' do
      it 'returns array of rates' do
        savon.expects(:get_property_rates).with(message: :any).returns(success_response)

        result = subject.call(params)
        rates = result.value

        expect(result).to be_a Result
        expect(result).to be_success
        expect(rates).to eq(many_rates)
      end
    end

    context 'when one rate' do
      it 'returns array with a rate' do
        savon.expects(:get_property_rates).with(message: :any).returns(one_rate_response)

        result = subject.call(params)
        rates = result.value

        expect(result).to be_a Result
        expect(result).to be_success
        expect(rates).to eq(one_rate)
      end
    end

    it 'returns empty array for empty response' do
      savon.expects(:get_property_rates).with(message: :any).returns(empty_response)

      result = subject.call(params)
      rates = result.value

      expect(result).to be_a Result
      expect(result).to be_success
      expect(rates).to be_empty
    end
  end
end