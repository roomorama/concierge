require 'spec_helper'

RSpec.describe Workers::Suppliers::Kigo::Legacy::Property do
  include Support::Fixtures
  include Support::Factories
  include Support::HTTPStubbing

  let(:references) {
    Result.new({
      amenities: JSON.parse(read_fixture('kigo/amenities.json')),
      property_types: JSON.parse(read_fixture('kigo/property_types.json')),
    })
  }
  before do
    allow_any_instance_of(Kigo::Importer).to receive(:fetch_references) { references }
  end

  let!(:supplier) { create_supplier(name: 'KigoLegacy') }
  let(:property_id) { '237294' }

  subject { described_class.new(property_id) }

  context "property belongs to existing host" do

    before { create_host(supplier_id: supplier.id, identifier: '508') }  # from kigo_legacy/property_data.json

    context 'when all network calls is successful' do
      let(:property_data) { JSON.parse(read_fixture('kigo_legacy/property_data.json')) }
      let(:periodical_rates) { JSON.parse(read_fixture('kigo/pricing_setup.json')) }

      before do
        allow_any_instance_of(Kigo::Importer).to receive(:fetch_data) { Result.new(property_data) }
        allow_any_instance_of(Kigo::Importer).to receive(:fetch_prices) { Result.new(periodical_rates) }
      end

      it 'finalizes synchronisation' do
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

        expect_any_instance_of(Workers::PropertySynchronisation).to receive(:finish!)
        subject.perform
      end

      it 'doesnt create property with unsuccessful publishing' do
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.error('fail') }
        expect {
          subject.perform
        }.to_not change { PropertyRepository.count }
      end

      it 'creates a property in database' do
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
        expect {
          subject.perform
        }.to change { PropertyRepository.count }.by(1)
      end
    end

    context "when fetching property return E_NOSUCH" do
      before do
        host = create_host(supplier_id: supplier.id, identifier: '12345')
        create_property(supplier_id: supplier.id, identifier: property_id, host_id: host.id)
        allow_any_instance_of(Kigo::Importer).to receive(:fetch_data) { Result.error(:record_not_found) }
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      end
      it "finalizes with the disabled property" do
        expect_any_instance_of(Workers::PropertySynchronisation).to receive(:finish!)
        subject.perform
      end
    end

    context "when fetching property data fails" do
      before { allow_any_instance_of(Kigo::Importer).to receive(:fetch_data) { Result.error(:connection_timeout) } }
      it 'announces an error if fetching data fails' do
        result = subject.perform
        expect(result.error.code).to eq :connection_timeout
      end
    end

    context "when rate limit is hit" do
      before do
        stub_call(:post, "https://app.kigo.net/api/ra/v1/readProperty2?subscription-key=123-key") {
          [429, {}, read_fixture('kigo/rate_limit.json')]
        }
      end
      it 'returns the 429 http error' do
        result = subject.perform
        expect(result.error.code).to eq :http_status_429
      end
    end
  end

  context "property belongs to new unregistered host" do
    let(:property_data) { JSON.parse(read_fixture('kigo/property_data.json')) }

    before do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_data) { Result.new(property_data) }
      expect(HostRepository.identified_by("15826").first).to be_nil  # from fixtures/kigo/property_data.json#RA_ID
    end

    it 'does not process properties with unknown host' do
      expect_any_instance_of(Workers::PropertySynchronisation).not_to receive(:start)
      subject.perform
    end
  end

  describe "#host_of" do
    context "when property fetching returns host identifier" do
      let(:property_fetch) { Result.new(JSON.parse(read_fixture('kigo/property_data.json'))) }

      context "and host identifier has been registered before" do
        before { create_host(supplier_id: supplier.id, identifier: '15826') }
        it { expect(subject.send(:host_of, property_fetch).identifier).to eq '15826' }
      end

      context "but host identifier has NOT been registered before" do
        before { expect(HostRepository.identified_by('15826').first).to be_nil }
        it { expect(subject.send(:host_of, property_fetch)).to be_nil }
      end
    end

    context "when property fetching returns E_NOSUCH" do
      let(:property_fetch) { Result.error(:record_not_found) }
      context "and property was ingested for a host before" do
        before do
          host = create_host(supplier_id: supplier.id, identifier: '12345')
          create_property(supplier_id: supplier.id, identifier: property_id, host_id: host.id)
        end

        it { expect(subject.send(:host_of, property_fetch).identifier).to eq '12345' }
      end
    end
  end
end
