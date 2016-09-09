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
          DateTime.new(2014, 6, 27),
          DateTime.new(2014, 8, 22),
          156.50
        ),
        Avantio::Entities::Rate::Period.new(
          DateTime.new(2014, 8, 23),
          DateTime.new(2014, 10, 16),
          157.50
        ),
        Avantio::Entities::Rate::Period.new(
          DateTime.new(2014, 10, 17),
          DateTime.new(2020, 10, 16),
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
      [
        Avantio::Entities::Availability::Period.new(
          DateTime.new(2014, 8, 24),
          DateTime.new(2014, 8, 27),
          'AVAILABLE'
        ),
        Avantio::Entities::Availability::Period.new(
          DateTime.new(2014, 8, 27),
          DateTime.new(2014, 8, 31),
          'UNAVAILABLE'
        ),
        Avantio::Entities::Availability::Period.new(
          DateTime.new(2014, 9, 11),
          DateTime.new(2020, 10, 16),
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
          2,
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
      before = Date.today + length
      invalid_entries = calendar.entries.select { |e| e.date <= Date.today || before < e.date }

      expect(invalid_entries).to be_empty
    end

    it 'returns unavailable entries for unavailable days' do
      entry = calendar.entries.detect { |e| e.date == Date.new(2014, 8, 28) }

      expect(entry.nightly_rate).to eq(157.5)
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
