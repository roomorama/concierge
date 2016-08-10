require 'spec_helper'
require 'savon/mock/spec_helper'

RSpec.describe Ciirus::Commands::QuoteFetcher do
  include Support::Fixtures
  include Savon::SpecHelper

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url: 'http://proxy.roomorama.com/ciirus')
  end

  let(:params) do
    API::Controllers::Params::Quote.new(property_id: 38180,
                                        check_in: '2016-05-01',
                                        check_out: '2016-05-12',
                                        guests: 3)
  end

  before { savon.mock! }
  after { savon.unmock! }

  let(:success_response) { read_fixture('ciirus/property_quote_response.xml') }
  subject { described_class.new(credentials) }

  describe '#call' do
    it 'returns success quotation' do
      savon.expects(:get_properties).with(message: :any).returns(success_response)

      result = subject.call(params)

      expect(result).to be_a Result
      expect(result).to be_success
      expect(result.value).to be_a Quotation
    end

    it 'fills quotation with right attributes' do
      savon.expects(:get_properties).with(message: :any).returns(success_response)

      result = subject.call(params)

      quotation = result.value
      expect(quotation.check_in).to eq('2016-05-01')
      expect(quotation.check_out).to eq('2016-05-12')
      expect(quotation.guests).to eq(3)
      expect(quotation.property_id).to eq('38180')
      expect(quotation.currency).to eq('USD')
      expect(quotation.available).to be true
      expect(quotation.total).to eq(3440.98)
    end
  end
end