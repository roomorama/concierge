require "spec_helper"

RSpec.describe THH::Price do
  include Support::Fixtures
  include Support::HTTPStubbing
  include Support::Factories

  let!(:supplier) { create_supplier(name: THH::Client::SUPPLIER_NAME) }
  let!(:host) { create_host(supplier_id: supplier.id, fee_percentage: 5) }
  let!(:property) do
    create_property(
      identifier: '15',
      host_id: host.id,
      data: { max_guests: 3 }
    )
  end
  let(:credentials) { double(key: 'Foo', url: 'http://example.org') }
  let(:params) {
    { property_id: '15', check_in: '2016-12-17', check_out: '2016-12-26', guests: 3 }
  }
  let(:quote_response) do
    Concierge::SafeAccessHash.new(
      {
        available: 'yes',
        price: '48,000'
      }
    )
  end

  let(:unavailable_quote_response) do
    Concierge::SafeAccessHash.new(
      {
        available: 'no',
        price: '48,000'
      }
    )
  end

  subject { described_class.new(credentials) }

  describe '#quote' do
    it 'returns an error if fetcher fails' do
      params[:guests] = 4
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :max_guests_exceeded
      expect(result.error.data).to eq 'The maximum number of guests to book this apartment is 3'
    end

    it 'returns an error if guest exceeds max guests of property' do
      allow_any_instance_of(THH::Commands::QuoteFetcher).to receive(:call) { Result.error(:error, 'Some error') }
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :error
      expect(result.error.data).to eq 'Some error'
    end

    it 'returns an unavailable quotation' do
      allow_any_instance_of(THH::Commands::QuoteFetcher).to receive(:call) { Result.new(unavailable_quote_response) }
      result = subject.quote(params)

      expect(result).to be_success
      quotation = result.value

      expect(quotation).to be_a Quotation
      expect(quotation.available).to eq false
      expect(quotation.property_id).to eq '15'
      expect(quotation.check_in).to eq '2016-12-17'
      expect(quotation.check_out).to eq '2016-12-26'
      expect(quotation.guests).to eq 3
      expect(quotation.currency).to be_nil
      expect(quotation.total).to be_nil
    end

    it 'returns an available quotation properly priced according to the response' do
      allow_any_instance_of(THH::Commands::QuoteFetcher).to receive(:call) { Result.new(quote_response) }

      result = subject.quote(params)

      expect(result).to be_success
      quotation = result.value

      expect(quotation).to be_a Quotation
      expect(quotation.available).to eq true
      expect(quotation.property_id).to eq '15'
      expect(quotation.check_in).to eq '2016-12-17'
      expect(quotation.check_out).to eq '2016-12-26'
      expect(quotation.guests).to eq 3
      expect(quotation.currency).to eq 'THB'
      expect(quotation.host_fee_percentage).to eq 5
      expect(quotation.total).to eq 48000.0 # rental + mandatory services
    end
  end
end
