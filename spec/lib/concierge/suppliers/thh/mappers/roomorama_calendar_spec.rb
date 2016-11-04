require 'spec_helper'

RSpec.describe THH::Mappers::RoomoramaCalendar do
  include Support::Fixtures

  let(:property) { parsed_property('thh/properties_response.xml') }
  let(:property_id) { property['property_id'] }

  subject { described_class.new }

  let(:calendar) { subject.build(property) }

  before do
    allow(Date).to receive(:today).and_return(Date.new(2016, 12, 10))
  end

  describe '#build' do
    it 'returns roomorama calendar' do
      expect(calendar).to be_a(Roomorama::Calendar)
      expect { calendar.validate! }.to_not raise_error
      expect(calendar.identifier).to eq(property_id)
    end

    it 'returns not empty calendar' do
      expect(calendar.entries).not_to be_empty
    end


    it 'returns calendar only from synced period' do
      invalid_entries = calendar.entries.select { |e| e.date < subject.calendar_start || subject.calendar_end < e.date }

      expect(invalid_entries).to be_empty
    end

    it 'returns reserved days as not available' do
      entry = calendar.entries.detect { |e| e.date == Date.new(2016, 12, 25) }

      expect(entry.available).to be false
    end

    it 'allows to arrive in day of departure' do
      entry = calendar.entries.detect { |e| e.date == Date.new(2016, 12, 26) }

      expect(entry.available).to be true
    end

    it 'returns filled entries' do
      entry = calendar.entries.detect { |e| e.date == Date.new(2017, 10, 2) }

      expect(entry.nightly_rate).to eq(10068.0)
      expect(entry.available).to be true
      expect(entry.minimum_stay).to eq(1)
    end
  end

  def parsed_property(name)
    parser = Nori.new
    response = parser.parse(read_fixture(name))['response']
    Concierge::SafeAccessHash.new(response['property'])
  end
end
