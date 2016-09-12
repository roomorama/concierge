require "spec_helper"

RSpec.describe Avantio::Price do
  include Support::Fixtures
  include Support::Factories

  let!(:host) { create_host(fee_percentage: 7) }
  let!(:property) { create_property(identifier: '123', host_id: host.id) }
  let(:credentials) do
    double(username: 'Foo', password: '123')
  end
  let(:params) do
    API::Controllers::Params::Quote.new(property_id: '123',
                                        check_in: '2017-08-01',
                                        check_out: '2017-08-05',
                                        guests: 2)
  end

  subject { described_class.new(credentials) }

  describe '#quote' do
    it 'fails if property is not found' do
      params.property_id = 'unknown id'
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :property_not_found
    end

    it 'fails if host is not found' do
      allow(subject).to receive(:fetch_host) { nil }
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :host_not_found
    end

    it 'fails when is_available request fails' do
      allow_any_instance_of(Avantio::Commands::IsAvailableFetcher).to receive(:call) { Result.error(:error) }

      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :error
    end

    it 'fails when quote request fails' do
      allow_any_instance_of(Avantio::Commands::IsAvailableFetcher).to receive(:call) { Result.new(true) }
      allow_any_instance_of(Avantio::Commands::QuoteFetcher).to receive(:call) { Result.error(:error) }

      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :error
    end

    it 'returns unavailable quotation if accommodation is unavailable' do
      allow_any_instance_of(Avantio::Commands::IsAvailableFetcher).to receive(:call) { Result.new(false) }
      expect_any_instance_of(Avantio::Commands::QuoteFetcher).to_not receive(:call)
      result = subject.quote(params)

      quotation = result.value
      expect(quotation.check_in).to eq('2017-08-01')
      expect(quotation.check_out).to eq('2017-08-05')
      expect(quotation.guests).to eq(2)
      expect(quotation.property_id).to eq('123')
      expect(quotation.available).to be false
    end

    it 'fills quotation with right attributes' do
      allow_any_instance_of(Avantio::Commands::IsAvailableFetcher).to receive(:call) { Result.new(true) }
      allow_any_instance_of(Avantio::Commands::QuoteFetcher).to receive(:call) do
        Result.new(Avantio::Entities::Quotation.new(698.19, 'USD'))
      end
      result = subject.quote(params)

      quotation = result.value
      expect(quotation.check_in).to eq('2017-08-01')
      expect(quotation.check_out).to eq('2017-08-05')
      expect(quotation.guests).to eq(2)
      expect(quotation.property_id).to eq('123')
      expect(quotation.currency).to eq('USD')
      expect(quotation.available).to be true
      expect(quotation.total).to eq(698.19)
      expect(result.value.host_fee_percentage).to eq(7)
    end
  end
end