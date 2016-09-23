require 'spec_helper'

RSpec.describe Kigo::Calendar::Period do

  let(:today) { Date.today }
  let(:year_from_today) { today + 365 }
  let(:start_date) { today + 10 }
  let(:end_date) { start_date + 10 }
  let(:period) {
    { 'CHECK_IN'        => start_date.to_s,
      'CHECK_OUT'       => end_date.to_s,
      'NAME'            => '',
      'STAY_MIN'        => { 'UNIT' => 'NIGHT', 'NUMBER' => 5 },
      'WEEKLY'          => false,
      'NIGHTLY_AMOUNTS' => [
        {
          'GUESTS_FROM' => 1,
          'WEEK_NIGHTS' => [1, 2, 3, 4, 5, 6, 7],
          'STAY_FROM'   => { 'UNIT' => 'NIGHT', 'NUMBER' => 7 },
          'AMOUNT'      => '35.26'
        },
        {
          'GUESTS_FROM' => 1,
          'WEEK_NIGHTS' => [1, 2, 3, 4, 5, 6, 7],
          'STAY_FROM'   => { 'UNIT' => 'NIGHT', 'NUMBER' => 5 },
          'AMOUNT'      => '36.26'
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
      expect(subject.entries.size).to eq 10

      entry = subject.entries.first

      expect(entry.date).to eq start_date
      expect(entry.nightly_rate).to eq 35.26
      expect(entry.minimum_stay).to eq 5
      expect(entry.checkin_allowed).to eq true
      expect(entry.checkout_allowed).to eq true
    end

    context 'unavailable minimum stay' do
      let(:period) do
        {
          'CHECK_IN'        => start_date.to_s,
          'CHECK_OUT'       => end_date.to_s,
          'NAME'            => '',
          'STAY_MIN'        => { 'UNIT' => 'NIGHT', 'NUMBER' => 0 },
          'WEEKLY'          => false,
          'NIGHTLY_AMOUNTS' => [
            {
              'GUESTS_FROM' => 1,
              'WEEK_NIGHTS' => [1, 2, 3, 4, 5, 6, 7],
              'STAY_FROM'   => { 'UNIT' => 'NIGHT', 'NUMBER' => 7 },
              'AMOUNT'      => '36.26'
            }
          ]
        }
      end

      it 'returns entry with min stay set to nil if NUMBER value is zero' do
        entry = subject.entries.first

        expect(entry.minimum_stay).to be_nil
      end
    end
  end
end
