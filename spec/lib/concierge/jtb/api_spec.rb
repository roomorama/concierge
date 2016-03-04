require 'spec_helper'

RSpec.describe Jtb::Api do
  include Support::Fixtures
  include Support::JtbClientHelper

  let(:credentials) {
    { id: 'some id', user: 'Roberto', password: '123', company: 'Apple' }
  }
  subject { described_class.new(credentials) }

  context 'builder' do

    describe '#build_availabilities' do
      let(:params) {
        { property_id: 10, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2, room_type_code: 'JPN' }
      }
      let(:message) { subject.build_availabilities(params) }

      it { expect(message.first).to be_a Nokogiri::XML::Element }

      context 'credentials' do
        it { expect(attribute_for(message, 'RequestorID', 'ID')).to eq credentials[:id] }
        it { expect(attribute_for(message, 'RequestorID', 'UserName')).to eq credentials[:user] }
        it { expect(attribute_for(message, 'RequestorID', 'MessagePassword')).to eq credentials[:password] }
        it { expect(attribute_for(message, 'CompanyName', 'Code')).to eq credentials[:company] }
      end

      context 'parameters' do
        it { expect(attribute_for(message, 'HotelCode', 'Code')).to eq params[:property_id].to_s }
        it { expect(attribute_for(message, 'RoomStayCandidate', 'RoomTypeCode')).to eq params[:room_type_code] }
        it { expect(attribute_for(message, 'StayDateRange', 'Start')).to eq params[:check_in].to_s }
        it { expect(attribute_for(message, 'StayDateRange', 'End')).to eq params[:check_out].to_s }
      end

    end
  end

  context 'requests' do
    before(:all) { savon.mock! }
    after(:all)  { savon.unmock! }

    describe '#quote_price' do
      let(:message) { subject.build_availabilities({}) }
      let(:fixture) { read_fixture('jtb/GA_HotelAvailRS.xml') }

      it 'returns hash' do
        savon.expects(:gby010).with(message: message.to_xml).returns(fixture)

        response = subject.quote_price({})
        expect(response).to be_a Hash
      end
    end

  end
end