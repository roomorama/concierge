require 'spec_helper'
require 'savon/mock/spec_helper'

RSpec.describe JTB::API do
  include Support::Fixtures
  include Savon::SpecHelper

  before(:all) { savon.mock! }
  after(:all) { savon.unmock! }

  let(:credentials) { double(id: 'some id', user: 'Roberto', password: '123', company: 'Apple') }
  subject { described_class.new(credentials) }

  describe '#quote_price' do
    let(:quote_success) { 'jtb/GA_HotelAvailRS.xml' }
    let(:fixture) { read_fixture(quote_success) }

    it 'returns result' do
      savon.expects(:gby010).with(message: :any).returns(fixture)

      response = subject.quote_price({})
      expect(response).to be_a Result
    end
  end

end