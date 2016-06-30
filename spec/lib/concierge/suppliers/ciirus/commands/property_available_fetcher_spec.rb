require 'spec_helper'
require 'savon/mock/spec_helper'

RSpec.describe Ciirus::Commands::PropertyAvailableFetcher do
  include Support::Fixtures
  include Savon::SpecHelper

  before { savon.mock! }
  after { savon.unmock! }

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://proxy.roomorama.com/ciirus')
  end

  let(:params) do
    {
      property_id: 38180,
      check_in: '2016-05-01',
      check_out: '2016-05-12',
      guests: 3
    }
  end

  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }
  let(:success_response) { read_fixture('ciirus/is_property_available_response.xml') }

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
    it 'returns property availability' do
      savon.expects(:is_property_available).with(message: :any).returns(success_response)

      result = subject.call(params)

      expect(result).to be_a Result
      expect(result).to be_success
      expect(result.value).to be false
    end
  end
end