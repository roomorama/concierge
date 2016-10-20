require 'spec_helper'

RSpec.describe JTB::XMLBuilder do

  let(:credentials) do
    {
      'id' => 'some id',
      'user' => 'Roberto',
      'password' => '123',
      'company' => 'Apple',
      'url' => 'https://trial-www.jtbgenesis.com/genesis2-demo/services',
      'test' => true
    }
  end
  subject { described_class.new(credentials) }

  describe '#quote_price' do
    let(:property_id) { 10 }
    let(:room_type_code) { 'JPN' }
    let(:check_in) { Date.today + 10 }
    let(:check_out) { Date.today + 20 }
    let(:message) { subject.quote_price(property_id, room_type_code, check_in, check_out) }

    it { expect(message.first).to be_a Nokogiri::XML::Element }

    context 'credentials' do
      it { expect(attribute_for(message, 'RequestorID', 'ID')).to eq credentials['id'] }
      it { expect(attribute_for(message, 'RequestorID', 'UserName')).to eq credentials['user'] }
      it { expect(attribute_for(message, 'RequestorID', 'MessagePassword')).to eq credentials['password'] }
      it { expect(attribute_for(message, 'CompanyName', 'Code')).to eq credentials['company'] }
    end

    context 'parameters' do
      it { expect(attribute_for(message, 'HotelCode', 'Code')).to eq property_id.to_s }
      it { expect(attribute_for(message, 'RoomStayCandidate', 'RoomTypeCode')).to eq room_type_code }
      it { expect(attribute_for(message, 'StayDateRange', 'Start')).to eq check_in.to_s }
      it { expect(attribute_for(message, 'StayDateRange', 'End')).to eq check_out.to_s }
    end

  end

  describe '#build_booking' do
    let(:room_type_code) { 'JPN' }
    let(:params) {
      {
        property_id: 'A123',
        unit_id:     'JPN|CHUHW01RM0000001',
        check_in:    '2016-03-22',
        check_out:   '2016-03-24',
        guests:      2,
        customer:    {
          first_name:  'Alex',
          last_name:   'Black',
          gender:      'male'
        }
      }
    }
    let(:rate_plan) { JTB::RatePlan.new('sample', 2000, true, 2) }
    let(:message) { subject.build_booking(params, rate_plan, room_type_code) }

    it { expect(attribute_for(message, 'RatePlan', 'RatePlanID')).to eq 'sample' }
    it { expect(attribute_for(message, 'RoomType', 'RoomTypeCode')).to eq room_type_code }
    it { expect(attribute_for(message, 'TimeSpan', 'StartDate')).to eq params[:check_in] }
    it { expect(attribute_for(message, 'TimeSpan', 'EndDate')).to eq params[:check_out] }
    it { expect(attribute_for(message, 'HotelReservation', 'PassiveIndicator')).to eq 'true' }

    context 'customer' do
      let(:customer) { params[:customer] }

      it { expect(message.xpath('//jtb:ResGuest').size).to eq(params[:guests]) }
      it { expect(message.xpath('//jtb:GivenName').first.text).to include(customer[:first_name]) }
      it { expect(message.xpath('//jtb:Surname').first.text).to include(customer[:last_name]) }
      it { expect(message.xpath('//jtb:NamePrefix').first.text).to eq('Mr') }

      it 'converts accented latin letters to ascii encoding' do
        params[:customer].merge!(first_name: 'Ĕřïć', last_name: 'BÁŔBÈÅÜ')
        message = subject.build_booking(params, rate_plan, room_type_code)

        expect(message.xpath('//jtb:GivenName').first.text).to be_ascii_only
        expect(message.xpath('//jtb:GivenName').first.text).to eq 'Eric'

        expect(message.xpath('//jtb:Surname').first.text).to be_ascii_only
        expect(message.xpath('//jtb:Surname').first.text).to eq 'BARBEAU'
      end

      context 'invalid name' do
        it 'set default first name and last name if non-latin letters' do
          params[:customer].merge!(first_name: 'Игорь', last_name: 'Трофимов')
          message = subject.build_booking(params, rate_plan, room_type_code)

          expect(message.xpath('//jtb:GivenName').first.text).to eq 'Roomorama'
          expect(message.xpath('//jtb:Surname').first.text).to eq 'Guest'
        end
      end
    end
  end

  private

  def attribute_for(message, tag, attribute)
    message.xpath("//jtb:#{tag}").map { |item| item[attribute] }.first
  end

end