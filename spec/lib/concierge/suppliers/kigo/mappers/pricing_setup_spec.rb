require 'spec_helper'

RSpec.describe Kigo::Mappers::PricingSetup do
  include Support::Fixtures

  let(:periodical_rates) { JSON.parse(read_fixture('kigo/pricing_setup.json'))['PRICING'] }
  let(:base_rate) { JSON.parse(read_fixture('kigo/property_data.json'))['PROP_RATE'] }

  subject { described_class.new(base_rate, wrap_hash(periodical_rates)) }

  it { expect(subject.currency).to eq 'EUR' }
  it { expect(subject.nightly_rate).to eq 151.98 }
  it { expect(subject.weekly_rate).to eq subject.nightly_rate * 7 }
  it { expect(subject.monthly_rate).to eq subject.nightly_rate * 30 }

  describe '#nightly_rate' do

    it 'uses base weekly price if daily nil' do
      base_rate['PROP_RATE_NIGHTLY_FROM'] = nil
      base_rate['PROP_RATE_WEEKLY_FROM']  = '700.00'

      subject = described_class.new(base_rate, periodical_rates)

      expect(subject).to be_valid
      expect(subject.nightly_rate).to eq 100
      expect(subject.weekly_rate).to eq 700
      expect(subject.monthly_rate).to eq 3000
    end

    it 'uses base weekly price if daily nil' do
      base_rate['PROP_RATE_NIGHTLY_FROM'] = nil
      base_rate['PROP_RATE_MONTHLY_FROM'] = '3000.00'

      subject = described_class.new(base_rate, periodical_rates)

      expect(subject).to be_valid
      expect(subject.nightly_rate).to eq 100
      expect(subject.weekly_rate).to eq 700
      expect(subject.monthly_rate).to eq 3000
    end

    context 'periodical price' do
      let(:base_rate) { {} }
      let(:weekly_rates) {
        [
          {
            'CHECK_IN'       => '2014-01-06',
            'CHECK_OUT'      => '2014-06-02',
            'NAME'           => 'Low Season',
            'STAY_MIN'       => { 'UNIT' => 'NIGHT', 'NUMBER' => 7 },
            'WEEKLY'         => true,
            'WEEKLY_AMOUNTS' => [
              { 'GUESTS_FROM' => 1, 'AMOUNT' => '3000.00' }
            ]
          }
        ]
      }

      it { expect(subject.nightly_rate).to eq 23.46 }

      it 'returns daily price according to weekly rates' do
        periodical_rates['RENT']['PERIODS'] = weekly_rates

        expected_rate = 3000.0 / 7
        subject       = described_class.new(base_rate, wrap_hash(periodical_rates))

        expect(subject).to be_valid
        expect(subject.nightly_rate).to eq expected_rate
        expect(subject.weekly_rate).to eq 3000
        expect(subject.monthly_rate).to eq expected_rate * 30
      end

      it 'raises a specific error without periodical rates' do
        subject = described_class.new(base_rate, wrap_hash({}))
        expect(subject).not_to be_valid
      end

    end

  end

  describe '#minimum_stay' do
    it 'sets minimum_stay to 0 when min stay rules are empty' do
      periodical_rates['MIN_STAY']['MIN_STAY_RULES'] = []
      subject = described_class.new(base_rate, wrap_hash(periodical_rates))

      expect(subject).to be_valid
      expect(subject.minimum_stay).to eq 0
    end

    it 'sets minimum_stay when min stay rules does not exist for given date' do
      allow(DateTime).to receive(:now) { DateTime.parse("2015-10-25") }

      periodical_rates['MIN_STAY']['MIN_STAY_RULES'] = [
        {
          "DATE_FROM"=>"2016-10-24",
          "DATE_TO"=>"2016-11-30",
          "LABEL"=>"Min Stay Fall Season",
          "MIN_STAY_VALUE"=>2
        }
      ]
      subject = described_class.new(base_rate, wrap_hash(periodical_rates))

      expect(subject).to be_valid
      expect(subject.minimum_stay).to eq 0
    end

    it 'sets minimum_stay when min stay rules exist for given date' do
      allow(DateTime).to receive(:now) { DateTime.parse("2016-10-25") }

      periodical_rates['MIN_STAY']['MIN_STAY_RULES'] = [
        {
          "DATE_FROM"=>"2016-10-24",
          "DATE_TO"=>"2016-11-30",
          "LABEL"=>"Min Stay Fall Season",
          "MIN_STAY_VALUE"=>2
        }
      ]
      subject = described_class.new(base_rate, wrap_hash(periodical_rates))

      expect(subject).to be_valid
      expect(subject.minimum_stay).to eq 2
    end

    it 'sets minimum_stay when min stay rules are from the beginning of the time and exist for given date' do
      allow(DateTime).to receive(:now) { DateTime.parse("2016-10-25") }

      periodical_rates['MIN_STAY']['MIN_STAY_RULES'] = [
        {
          "DATE_FROM"=>nil,
          "DATE_TO"=>"2016-11-30",
          "LABEL"=>"Min Stay Fall Season",
          "MIN_STAY_VALUE"=>2
        }
      ]
      subject = described_class.new(base_rate, wrap_hash(periodical_rates))

      expect(subject).to be_valid
      expect(subject.minimum_stay).to eq 2
    end

    it 'sets minimum_stay when min stay rules are till the end of time and exist for given date' do
      allow(DateTime).to receive(:now) { DateTime.parse("2016-10-25") }

      periodical_rates['MIN_STAY']['MIN_STAY_RULES'] = [
        {
          "DATE_FROM"=>"2016-10-24",
          "DATE_TO"=>nil,
          "LABEL"=>"Min Stay Fall Season",
          "MIN_STAY_VALUE"=>2
        }
      ]
      subject = described_class.new(base_rate, wrap_hash(periodical_rates))

      expect(subject).to be_valid
      expect(subject.minimum_stay).to eq 2
    end

    it 'sets minimum_stay by using the first matched min stay rule' do
      allow(DateTime).to receive(:now) { DateTime.parse("2016-11-01") }

      periodical_rates['MIN_STAY']['MIN_STAY_RULES'] = [
        {
          "DATE_FROM"=>"2016-10-26",
          "DATE_TO"=>"2016-10-28",
          "LABEL"=>"Min Stay Fall Season",
          "MIN_STAY_VALUE"=>2
        },
        {
          "DATE_FROM"=>"2016-10-28",
          "DATE_TO"=>"2016-11-03",
          "LABEL"=>"Min Stay Fall Season",
          "MIN_STAY_VALUE"=>3
        },
        {
          "DATE_FROM"=>"2016-11-04",
          "DATE_TO"=>"2016-11-07",
          "LABEL"=>"Min Stay Fall Season",
          "MIN_STAY_VALUE"=>4
        }
      ]
      subject = described_class.new(base_rate, wrap_hash(periodical_rates))

      expect(subject).to be_valid
      expect(subject.minimum_stay).to eq 3
    end

    it 'sets minimum_stay when min stay rules exist but date is less than DATE_FROM' do
      allow(DateTime).to receive(:now) { DateTime.parse("2016-10-23") }

      periodical_rates['MIN_STAY']['MIN_STAY_RULES'] = [
        {
          "DATE_FROM"=>"2016-10-24",
          "DATE_TO"=>"2016-11-30",
          "LABEL"=>"Min Stay Fall Season",
          "MIN_STAY_VALUE"=>2
        }
      ]
      subject = described_class.new(base_rate, wrap_hash(periodical_rates))

      expect(subject).to be_valid
      expect(subject.minimum_stay).to eq 0
    end

    it 'sets minimum_stay when min stay rules exist and date is equal to DATE_FROM' do
      allow(DateTime).to receive(:now) { DateTime.parse("2016-10-24") }

      periodical_rates['MIN_STAY']['MIN_STAY_RULES'] = [
        {
          "DATE_FROM"=>"2016-10-24",
          "DATE_TO"=>"2016-11-30",
          "LABEL"=>"Min Stay Fall Season",
          "MIN_STAY_VALUE"=>2
        }
      ]
      subject = described_class.new(base_rate, wrap_hash(periodical_rates))

      expect(subject).to be_valid
      expect(subject.minimum_stay).to eq 2
    end

    it 'sets minimum_stay when min stay rules exist and date is equal to DATE_TO' do
      allow(DateTime).to receive(:now) { DateTime.parse("2016-11-30") }

      periodical_rates['MIN_STAY']['MIN_STAY_RULES'] = [
        {
          "DATE_FROM"=>"2016-10-24",
          "DATE_TO"=>"2016-11-30",
          "LABEL"=>"Min Stay Fall Season",
          "MIN_STAY_VALUE"=>2
        }
      ]
      subject = described_class.new(base_rate, wrap_hash(periodical_rates))

      expect(subject).to be_valid
      expect(subject.minimum_stay).to eq 2
    end

    it 'sets minimum_stay when min stay rules exist but date is greater than DATE_TO' do
      allow(DateTime).to receive(:now) { DateTime.parse("2016-12-01") }

      periodical_rates['MIN_STAY']['MIN_STAY_RULES'] = [
        {
          "DATE_FROM"=>"2016-10-24",
          "DATE_TO"=>"2016-11-30",
          "LABEL"=>"Min Stay Fall Season",
          "MIN_STAY_VALUE"=>2
        }
      ]
      subject = described_class.new(base_rate, wrap_hash(periodical_rates))

      expect(subject).to be_valid
      expect(subject.minimum_stay).to eq 0
    end
  end

  private

  def wrap_hash(hash)
    Concierge::SafeAccessHash.new(hash)
  end

end
