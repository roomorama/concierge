require 'spec_helper'

RSpec.describe Audit::Importer do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) { Concierge::Credentials.for('audit') }
  let(:importer) { described_class.new(credentials) }

  describe '#fetch_properties' do

    subject { importer.fetch_properties }

    context 'success' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:get) do
          Faraday::Response.new(method: :get, status: 200, body: IO.binread('spec/fixtures/audit/properties.json'))
        end
      end

      it 'should return Result of array of Hash' do
        is_expected.to be_success
        expect(subject.value).to be_kind_of(Array)
        expect(subject.value.collect(&:class).uniq).to eq([Hash])
      end
    end

    context 'error' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:get) do
          raise Faraday::Error.new("oops123")
        end
      end

      it 'should return Result with errors' do
        is_expected.not_to be_success
        expect(subject.error.code).to eq :network_failure
      end
    end
  end

  describe '#json_to_property' do
    let(:json) { JSON.parse(IO.binread('spec/fixtures/audit/properties.json'))['result'].sample }

    it 'should return Result of Roomorama::Property' do
      result = importer.json_to_property(json)
      expect(result).to be_kind_of(Result)
      expect(result.value).to be_kind_of(Roomorama::Property)
    end
  end
end
