require 'spec_helper'

RSpec.describe JTB::XMLBuilder do

  let(:credentials) { double(id: 'some id', user: 'Roberto', password: '123', company: 'Apple') }
  subject { described_class.new(credentials) }

  describe '#quote_price' do
    let(:params) {
      { property_id: 10, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2, unit_id: 'JPN' }
    }
    let(:message) { subject.quote_price(params) }

    it { expect(message.first).to be_a Nokogiri::XML::Element }

    context 'credentials' do
      it { expect(attribute_for(message, 'RequestorID', 'ID')).to eq credentials.id }
      it { expect(attribute_for(message, 'RequestorID', 'UserName')).to eq credentials.user }
      it { expect(attribute_for(message, 'RequestorID', 'MessagePassword')).to eq credentials.password }
      it { expect(attribute_for(message, 'CompanyName', 'Code')).to eq credentials.company }
    end

    context 'parameters' do
      it { expect(attribute_for(message, 'HotelCode', 'Code')).to eq params[:property_id].to_s }
      it { expect(attribute_for(message, 'RoomStayCandidate', 'RoomTypeCode')).to eq params[:unit_id] }
      it { expect(attribute_for(message, 'StayDateRange', 'Start')).to eq params[:check_in].to_s }
      it { expect(attribute_for(message, 'StayDateRange', 'End')).to eq params[:check_out].to_s }
    end

  end

  private

  def attribute_for(message, tag, attribute)
    message.xpath("//jtb:#{tag}").map { |item| item[attribute] }.first
  end

end