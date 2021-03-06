require 'spec_helper'

RSpec.describe THH::Calendar do
  include Support::Fixtures

  let(:property) { parsed_property('thh/properties_response.xml') }
  let(:rates) { property.get('rates.rate') }
  let(:booked_dates) { property.get('calendar.booked.date') }
  let(:length) { 365 }

  subject { described_class.new(rates, booked_dates, length)}

  before do
    allow(Date).to receive(:today).and_return(Date.new(2016, 12, 10))
  end

  describe '#has_available_days?' do
    it 'returns true if property has available days' do
      expect(subject.has_available_days?).to be true
    end

    context 'no available days' do
      let(:rates) do
        [
          {"start_date" => "15.12.2015", "end_date" => "20.12.2016", "title" => "Peak/2015", "night" => "8,820", "currency" => "THB", "min_nights" => "3"},
          {"start_date" => "01.01.2017", "end_date" => "05.01.2017", "title" => "High", "night" => "8,830", "currency" => "THB", "min_nights" => "3"}
        ]
      end
      let(:booked_dates) do
        [
          '2016-12-10',
          '2016-12-11',
          '2016-12-12',
          '2016-12-13',
          '2016-12-14',
          '2016-12-15',
          '2016-12-16',
          '2016-12-17',
          '2016-12-18',
          '2016-12-19',
          '2016-12-20',
          '2017-01-01',
          '2017-01-02',
          '2017-01-03',
          '2017-01-04',
          '2017-01-05',
          '2017-01-06'
        ]
      end

      it 'returns false' do
        expect(subject.has_available_days?).to be false
      end
    end
  end

  describe '#min_stay' do
    it 'returns minimum stay' do
      expect(subject.min_stay).to eq(3)
    end
  end

  describe '#min_rate' do
    it 'returns minimum rate' do
      expect(subject.min_rate).to eq(8510.0)
    end
  end

  describe '#rates_days' do
    it 'returns hash of rates' do
      rates_days = subject.rates_days

      expect(rates_days).to be_a(Hash)
      expect(rates_days.keys).to all(be_a(Date))
      expect(rates_days.values).to all(be_a(Hash))
    end

    it 'does not return days less then today' do
      rates_days = subject.rates_days

      days = rates_days.keys.select { |d| d < Date.today }
      expect(days).to be_empty
    end

    it 'does not return days after the length' do
      rates_days = subject.rates_days

      days = rates_days.keys.select { |d| Date.today + length < d }
      expect(days).to be_empty
    end

    it 'does not return days without rates' do
      rates_days = subject.rates_days

      rate = rates_days[Date.new(2017, 1, 11)]
      expect(rate).to be_nil
    end

    it 'returns days with rates' do
      rates_days = subject.rates_days

      rate = rates_days[Date.new(2017, 1, 9)]
      expect(rate).not_to be_nil
      expect(rate[:night]).to eq(9400.0)
      expect(rate[:min_nights]).to eq(3)
    end
  end

  describe '#booked_days' do
    it 'returns set of booked days' do
      booked_days = subject.booked_days

      expect(booked_days).to be_a(Set)
      expect(booked_days).to all(be_a(Date))
    end

    it 'does not return days less then today' do
      booked_days = subject.booked_days

      days = booked_days.select { |d| d < Date.today }
      expect(days).to be_empty
    end

    it 'does not return days after the length' do
      booked_days = subject.booked_days

      days = booked_days.select { |d| Date.today + length < d }
      expect(days).to be_empty
    end

    it 'does not return not booked days' do
      booked_days = subject.booked_days

      expect(booked_days.include?(Date.new(2016, 12, 29))).to be false
    end

    it 'returns booked day' do
      booked_days = subject.booked_days

      expect(booked_days.include?(Date.new(2016, 12, 30))).to be true
    end

    it 'does not include end date of booked periods to the result' do
      booked_days = subject.booked_days
      rates_days = subject.rates_days

      expect(booked_days.include?(Date.new(2017, 1, 12))).to be false
      expect(rates_days.include?(Date.new(2017, 1, 13))).to be true
    end

    it 'include first date of booked period' do
      booked_days = subject.booked_days

      expect(booked_days.include?(Date.new(2016, 12, 30))).to be true
    end
  end

  def parsed_property(name)
    parser = Nori.new(advanced_typecasting: false)
    response = parser.parse(read_fixture(name))['response']
    Concierge::SafeAccessHash.new(response['property'])
  end
end
