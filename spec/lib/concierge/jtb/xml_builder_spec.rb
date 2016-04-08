require 'spec_helper'

RSpec.describe JTB::XMLBuilder do

  let(:credentials) { double(id: 'some id', user: 'Roberto', password: '123', company: 'Apple', url: 'https://trial-www.jtbgenesis.com/genesis2-demo/services') }
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
  
  describe '#build_booking' do
    let(:params) {
      {
        property_id: 'A123',
        unit_id:     'JPN',
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
    let(:message) { subject.build_booking(params, rate_plan) }
    
    it { expect(attribute_for(message, 'RatePlan', 'RatePlanID')).to eq 'sample' }
    it { expect(attribute_for(message, 'RoomType', 'RoomTypeCode')).to eq params[:unit_id] }
    it { expect(attribute_for(message, 'TimeSpan', 'StartDate')).to eq params[:check_in] }
    it { expect(attribute_for(message, 'TimeSpan', 'EndDate')).to eq params[:check_out] }

    context 'customer' do
      let(:customer) { params[:customer] }

      it { expect(message.xpath('//jtb:ResGuest').size).to eq(params[:guests]) }
      it { expect(message.xpath('//jtb:GivenName').first.text).to include(customer[:first_name]) }
      it { expect(message.xpath('//jtb:Surname').first.text).to include(customer[:last_name]) }
      it { expect(message.xpath('//jtb:NamePrefix').first.text).to eq('Mr') }

      it 'converts accented latin letters to ascii encoding' do
        params[:customer].merge!(first_name: 'Ĕřïć', last_name: 'BÁŔBÈÅÜ')
        message = subject.build_booking(params, rate_plan)

        expect(message.xpath('//jtb:GivenName').first.text).to be_ascii_only
        expect(message.xpath('//jtb:GivenName').first.text).to eq 'Eric'

        expect(message.xpath('//jtb:Surname').first.text).to be_ascii_only
        expect(message.xpath('//jtb:Surname').first.text).to eq 'BARBEAU'
      end

      context 'invalid name' do
        it 'set default first name and last name if non-latin letters' do
          params[:customer].merge!(first_name: 'Игорь', last_name: 'Трофимов')
          message = subject.build_booking(params, rate_plan)

          expect(message.xpath('//jtb:GivenName').first.text).to eq 'Roomorama'
          expect(message.xpath('//jtb:Surname').first.text).to eq 'Guest'
        end

        it 'set default first name and last name if name blank' do
          params[:customer].delete(:first_name)
          params[:customer].delete(:last_name)
          message = subject.build_booking(params, rate_plan)

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