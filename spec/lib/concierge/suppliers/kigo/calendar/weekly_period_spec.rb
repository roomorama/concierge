require 'spec_helper'

RSpec.describe Kigo::Calendar::WeeklyPeriod do

  let(:today) { Date.today }
  let(:year_from_today) { today + 365 }
  let(:start_date) { today + 10 }
  let(:end_date) { start_date + 13 }
  let(:period) {
    { 'CHECK_IN'        => start_date.to_s,
      'CHECK_OUT'       => end_date.to_s,
      'NAME'            => '',
      'STAY_MIN'        => { 'UNIT' => 'NIGHT', 'NUMBER' => 7 },
      'WEEKLY'          => true,
      'WEEKLY_AMOUNTS' => [
        {
          'GUESTS_FROM' => 1,
          'AMOUNT'      => '700.00'
        },
        {
          'GUESTS_FROM' => 1,
          'AMOUNT'      => '900.00'
        }
      ]
    }
  }

  subject { described_class.new(period) }


  it 'sets proper start and end dates' do
    subject = described_class.new(period)

    expect(subject.start_date).to eq start_date
    expect(subject.end_date).to eq end_date
  end

  context 'start date less then today' do
    let(:start_date) { today - 2 }

    it 'is valid and set date as today' do
      expect(subject.start_date).to eq today
      expect(subject).to be_valid
    end
  end

  context 'end date more then year from today' do
    let(:end_date) { year_from_today + 2 }

    it 'is valid and set date as year from today' do
      expect(subject.end_date).to eq year_from_today
      expect(subject).to be_valid
    end
  end

  context 'start and end dates less then today' do
    let(:start_date) { today - 20 }

    it { expect(subject).not_to be_valid }
  end

  context 'start and end dates more then year from today' do
    let(:start_date) { year_from_today + 1 }

    it { expect(subject).not_to be_valid }
  end

  describe '#entries' do
    it 'returns array of entries' do
      expect(subject.entries.size).to eq 14

      entry = subject.entries.first

      expect(entry.date).to eq start_date
      expect(entry.nightly_rate).to eq 100
      expect(entry.minimum_stay).to eq 7
      expect(entry.checkin_allowed).to eq true
      expect(entry.checkout_allowed).to eq true

      second_entry = subject.entries[1]

      expect(second_entry.date).to eq (start_date + 1)
      expect(second_entry.nightly_rate).to eq 100
      expect(second_entry.minimum_stay).to eq 7
      expect(second_entry.checkin_allowed).to eq false
      expect(second_entry.checkout_allowed).to eq false
    end
  end

end