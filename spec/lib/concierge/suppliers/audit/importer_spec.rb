require 'spec_helper'

RSpec.describe Audit::Importer do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) { Concierge::Credentials.for('audit') }
  let(:importer) { described_class.new(credentials) }
  let(:endpoint) { "#{credentials.host}#{credentials.fetch_properties_endpoint}" }

  describe '#fetch_properties' do

    subject { importer.fetch_properties }

    context 'success' do
      before do
        stub_call(:get, endpoint) { [200, {}, read_fixture('audit/fetch_properties.json')] }
      end

      it 'should return Result of array of Hash' do
        is_expected.to be_success
        expect(subject.value).to be_kind_of(Array)
        expect(subject.value.collect(&:class).uniq).to eq([Hash])
      end
    end

    context 'error' do
      before do
        stub_call(:get, endpoint) { raise Faraday::Error.new("oops123") }
      end

      it 'should return Result with errors' do
        is_expected.not_to be_success
        expect(subject.error.code).to eq :network_failure
      end
    end
  end

  describe '#json_to_property' do
    let(:json) { JSON.parse(read_fixture('audit/fetch_properties.json'))['result'].sample }

    it 'should return Result of Roomorama::Property' do
      result = importer.json_to_property(json)
      expect(result).to be_kind_of(Result)
      expect(result.value).to be_kind_of(Roomorama::Property)
    end
  end
end
