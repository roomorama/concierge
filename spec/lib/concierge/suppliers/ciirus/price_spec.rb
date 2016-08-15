require "spec_helper"

RSpec.describe Ciirus::Price do
  include Support::Fixtures
  include Support::Factories

  let!(:host) { create_host(fee_percentage: 7) }
  let!(:property) { create_property(identifier: '123', host_id: host.id) }
  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://proxy.roomorama.com/ciirus')
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
      result   = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :property_not_found
    end

    it 'fails if host is not found' do
      allow(subject).to receive(:fetch_host) { nil }
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :host_not_found
    end

    it 'fills host_fee_percentage' do
      allow_any_instance_of(Ciirus::Commands::QuoteFetcher).to receive(:call) { Result.new(Quotation.new) }

      result = subject.quote(params)
      expect(result).to be_success
      expect(result.value.host_fee_percentage).to eq(7)
    end
  end
end