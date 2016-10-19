require 'spec_helper'

RSpec.describe Avantio::Commands::AvailabilitiesFetcher do
  include Support::Fixtures

  let(:code_partner) { '5df48r9r6h' }
  let(:availabilities_xml) { xml_from_fixture('avantio/availabilities.xml') }

  subject { described_class.new(code_partner) }

  describe '#call' do
    context 'when fetcher returns error' do
      it 'returns result with error' do
        allow_any_instance_of(Avantio::Fetcher).to receive(:fetch) { Result.error(:error, 'Description') }
        result = subject.call

        expect(result).not_to be_success
        expect(result.error.code).to eq :error
        expect(result.error.data).to eq 'Description'
      end
    end

    context 'when xml response is correct' do
      it 'returns success hash of rates' do
        allow_any_instance_of(Avantio::Fetcher).to receive(:fetch) { Result.new(availabilities_xml) }
        result = subject.call

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a(Hash)
        expect(result.value.length).to eq(2)
        expect(result.value.values).to all(be_a Avantio::Entities::Availability)
      end

      it 'returns empty hash for empty response' do
        allow_any_instance_of(Avantio::Fetcher).to receive(:fetch) do
          xml = Nokogiri::XML('<GetAvailabilitiesRS><AccommodationList></AccommodationList></GetAvailabilitiesRS>')
          Result.new(xml)
        end

        result = subject.call

        rates = result.value
        expect(rates).to be_empty
      end

      it 'returns empty hash for unknown xml structure' do
        allow_any_instance_of(Avantio::Fetcher).to receive(:fetch) do
          xml = Nokogiri::XML('<foo></foo>')
          Result.new(xml)
        end

        result = subject.call

        rates = result.value
        expect(rates).to be_empty
      end
    end
  end

  def xml_from_fixture(filename)
    Nokogiri::XML(read_fixture(filename))
  end
end