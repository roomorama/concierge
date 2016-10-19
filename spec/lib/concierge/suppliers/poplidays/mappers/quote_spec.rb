require 'spec_helper'

RSpec.describe Poplidays::Mappers::Quote do
  include Support::Fixtures
  include Support::Factories

  let(:host) { create_host(fee_percentage: 5.0) }
  let!(:property) { create_property(identifier: '33680', host_id: host.id) }
  let(:mandatory_services) { 25.0 }
  let(:params) do
    API::Controllers::Params::Quote.new(property_id: '33680',
                                        check_in: '2017-08-01',
                                        check_out: '2017-08-05',
                                        guests: 2)
  end

  subject { described_class.new }
  let(:result) { subject.build(params, mandatory_services, quote) }

  context 'for success response' do
    let(:quote) do
      Result.new({
        'value' => 3410.28,
        'ruid'=> "09cdecc64b5ba9504c08bb598075262f"
      })
    end

    it 'returns available roomorama quotation entity' do
      expect(result).to be_a(Result)
      quotation = result.value
      expect(quotation).to be_a(::Quotation)
      expect(quotation.check_in).to eq('2017-08-01')
      expect(quotation.property_id).to eq('33680')
      expect(quotation.check_out).to eq('2017-08-05')
      expect(quotation.guests).to eq(2)
      expect(quotation.total).to eq(3435.28)
      expect(quotation.currency).to eq('EUR')
      expect(quotation.available).to be true
      expect(quotation.host_fee_percentage).to eq(5)
    end
  end

  context 'for response with error code' do
    let(:quote) do
      Result.error(:some_error_happened)
    end

    it 'returns not available roomorama quotation entity' do
      quotation = result.value
      expect(quotation).to be_a(::Quotation)
      expect(quotation.check_in).to eq('2017-08-01')
      expect(quotation.property_id).to eq('33680')
      expect(quotation.check_out).to eq('2017-08-05')
      expect(quotation.guests).to eq(2)
      expect(quotation.available).to be false
    end
  end

  context 'for response with error code' do
    let(:quote) do
      Result.new({
        'ruid'=> "09cdecc64b5ba9504c08bb598075262f"
      })
    end

    it 'returns error if unexpected quote structure' do
      expect(result).to_not be_success
      expect(result.error.code).to eq(:unexpected_quote)
      expect(result.error.data).to eq(
        "Unexpected quote: empty response result['value'] from API"
      )
    end
  end


end
