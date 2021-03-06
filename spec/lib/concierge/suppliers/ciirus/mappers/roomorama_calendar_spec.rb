require 'spec_helper'

RSpec.describe Ciirus::Mappers::RoomoramaCalendar do

  let(:property_id) { '33680' }
  let(:rates) do
    [
      Ciirus::Entities::PropertyRate.new(
        DateTime.new(2014, 6, 27),
        DateTime.new(2014, 8, 22),
        3,
        157.50
      ),
      Ciirus::Entities::PropertyRate.new(
        DateTime.new(2014, 8, 23),
        DateTime.new(2014, 10, 16),
        2,
        141.43
      ),
      Ciirus::Entities::PropertyRate.new(
        DateTime.new(2014, 10, 17),
        DateTime.new(2014, 11, 16),
        1,
        0.0
      ),
      Ciirus::Entities::PropertyRate.new(
        DateTime.new(2016, 12, 1),
        DateTime.new(2017, 10, 16),
        2,
        147.43
      )
    ]
  end

  let(:reservations) do
    [
      Ciirus::Entities::Reservation.new(
        DateTime.new(2014, 8, 24),
        DateTime.new(2014, 8, 27),
        '6507374',
        false,
        nil
      ),
      Ciirus::Entities::Reservation.new(
        DateTime.new(2014, 8, 27),
        DateTime.new(2014, 8, 31),
        '6525576',
        false,
        nil
      ),
      Ciirus::Entities::Reservation.new(
        DateTime.new(2014, 9, 11),
        DateTime.new(2014, 10, 16),
        '6507374',
        false,
        nil
      ),
    ]
  end

  subject { described_class.new }

  let(:calendar) { subject.build(property_id, rates, reservations) }
  let(:today) { Date.new(2014, 7, 14) }

  before do
    allow(Date).to receive(:today).and_return(today)
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

    it 'returns unavailable entries for rates with 0 price' do
      entries = calendar.entries.select { |e| e.date >= Date.new(2014, 10, 17) }

      expect(entries).not_to be_empty
      entries.each do |e|
        expect(e.available).to be_falsey
      end
    end

    it 'returns calendar only from synced period' do
      before = Date.today + described_class::PERIOD_SYNC
      invalid_entries = calendar.entries.select { |e| e.date <= Date.today || before < e.date }

      expect(invalid_entries).to be_empty
    end

    it 'returns reserved days as not available' do
      entry = calendar.entries.detect { |e| e.date == Date.new(2014, 8, 28) }

      expect(entry.nightly_rate).to eq(141.43)
      expect(entry.available).to be_falsey
    end

    it 'does not allow to arrive in day of arrival' do
      entry = calendar.entries.detect { |e| e.date == Date.new(2014, 9, 11) }

      expect(entry.available).to be_falsey
    end

    it 'allows to arrive in day of departure' do
      entry = calendar.entries.detect { |e| e.date == Date.new(2014, 10, 16) }

      expect(entry.available).to be_truthy
    end

    it 'returns filled entries' do
      entry = calendar.entries.detect { |e| e.date == Date.new(2014, 9, 1) }

      expect(entry.nightly_rate).to eq(141.43)
      expect(entry.available).to be_truthy
      expect(entry.minimum_stay).to eq(2)
    end
  end
end
