require 'spec_helper'

RSpec.describe Avantio::Mappers::RoomoramaCalendar do

  let(:property_id) { '33680' }
  let(:rate) do
    Avantio::Entities::Rate.new(
      '123',
      '123',
      '123',
      [
        Avantio::Entities::Rate::Period.new(
          Date.new(2014, 6, 27),
          Date.new(2014, 8, 22),
          156.50
        ),
        Avantio::Entities::Rate::Period.new(
          Date.new(2014, 8, 25),
          Date.new(2014, 10, 16),
          157.50
        ),
        Avantio::Entities::Rate::Period.new(
          Date.new(2014, 10, 17),
          Date.new(2020, 10, 16),
          158.50
        ),
      ]
    )
  end

  let(:availability) do
    Avantio::Entities::Availability.new(
      '123',
      '123',
      '123',
      '204',
      [
        Avantio::Entities::Availability::Period.new(
          Date.new(2014, 7, 13),
          Date.new(2014, 8, 16),
          'AVAILABLE'
        ),
        Avantio::Entities::Availability::Period.new(
          Date.new(2014, 8, 24),
          Date.new(2014, 8, 27),
          'AVAILABLE'
        ),
        Avantio::Entities::Availability::Period.new(
          Date.new(2014, 8, 27),
          Date.new(2014, 8, 31),
          'UNAVAILABLE'
        ),
        Avantio::Entities::Availability::Period.new(
          Date.new(2014, 9, 11),
          Date.new(2020, 10, 16),
          'AVAILABLE'
        ),
      ]
    )
  end
  let(:rule) do
    Avantio::Entities::OccupationalRule.new(
      '204',
      [
        Avantio::Entities::OccupationalRule::Season.new(
          Date.new(2014, 6, 10),
          Date.new(2020, 10, 16),
          1,
          (1..31).map(&:to_s),
          ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'],
          (1..31).map(&:to_s),
          ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'SATURDAY', 'SUNDAY']
        )
      ]
    )
  end
  let(:length) { 365 }

  subject { described_class.new(property_id, rate, availability, rule, length) }

  let(:calendar) { subject.build }

  before do
    allow(Date).to receive(:today).and_return(Date.new(2014, 7, 14))
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
      before = Date.today
      after = before + length
      invalid_entries = calendar.entries.select { |e| e.date < before || after < e.date }

      expect(invalid_entries).to be_empty
    end

    it "marks first #{described_class::MARGIN} days as unavailable"  do
      invalid_entries = calendar.entries.first(described_class::MARGIN)

      expect(invalid_entries.all? { |e| !e.available }).to be true
    end

    it 'returns unavailable entries for unavailable days' do
      entry = calendar.entries.detect { |e| e.date == Date.new(2014, 8, 28) }

      expect(entry.nightly_rate).to eq(157.5)
      expect(entry.available).to be false
    end

    it 'returns unavailable entries for days without rate' do
      entry = calendar.entries.detect { |e| e.date == Date.new(2014, 8, 24) }

      expect(entry.nightly_rate).to eq(0)
      expect(entry.available).to be false
    end

    it 'returns filled entries' do
      entry = calendar.entries.detect { |e| e.date == Date.new(2014, 9, 12) }

      expect(entry.nightly_rate).to eq(157.5)
      expect(entry.available).to be true
      expect(entry.minimum_stay).to eq(1)
      expect(entry.checkin_allowed).to be true
      expect(entry.checkout_allowed).to be false
    end
  end
end
