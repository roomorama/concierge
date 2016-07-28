require 'spec_helper'

RSpec.describe Poplidays::Mappers::Quote do
  include Support::Fixtures

  let(:mandatory_services) { 25.0 }
  let(:params) do
    API::Controllers::Params::Quote.new(property_id: '33680',
                                        check_in: '2017-08-01',
                                        check_out: '2017-08-05',
                                        guests: 2)
  end

  subject { described_class.new }
  let(:quotation) { subject.build(params, mandatory_services, quote) }

  context 'for success response' do
    let(:quote) do
      {
        'value' => 3410.28,
        'ruid'=> "09cdecc64b5ba9504c08bb598075262f"
      }
    end

    it 'returns available roomorama quotation entity' do
      expect(quotation).to be_a(::Quotation)
      expect(quotation.check_in).to eq('2017-08-01')
      expect(quotation.property_id).to eq('33680')
      expect(quotation.check_out).to eq('2017-08-05')
      expect(quotation.guests).to eq(2)
      expect(quotation.total).to eq(3435.28)
      expect(quotation.currency).to eq('EUR')
      expect(quotation.available).to be true
    end
  end

  context 'for response with error code' do
    let(:quote) do
      {
        'code' => 400,
        'message' => 'Unauthorized arriving day',
        'ruid' => '76b95928b4fec0ca2dc6ddb33e89b044'
      }
    end

    it 'returns available roomorama quotation entity' do
      expect(quotation).to be_a(::Quotation)
      expect(quotation.check_in).to eq('2017-08-01')
      expect(quotation.property_id).to eq('33680')
      expect(quotation.check_out).to eq('2017-08-05')
      expect(quotation.guests).to eq(2)
      expect(quotation.available).to be false
    end
  end
end