require 'spec_helper'

RSpec.describe Kigo::Mappers::PricingSetup do
  include Support::Fixtures

  let(:periodical_rates) { JSON.parse(read_fixture('kigo/pricing_setup.json'))['PRICING'] }
  let(:base_rate) { JSON.parse(read_fixture('kigo/property_data.json'))['PROP_RATE'] }

  subject { described_class.new(base_rate, periodical_rates) }

  it { expect(subject.currency).to eq 'EUR' }
  it { expect(subject.nightly_rate).to eq 151.98 }
  it { expect(subject.weekly_rate).to eq subject.nightly_rate * 7 }
  it { expect(subject.monthly_rate).to eq subject.nightly_rate * 30 }

  describe '#nightly_rate' do

    it 'uses base weekly price if daily nil' do
      base_rate['PROP_RATE_NIGHTLY_FROM'] = nil
      base_rate['PROP_RATE_WEEKLY_FROM'] = '700.00'

      subject = described_class.new(base_rate, periodical_rates)
      expect(subject.nightly_rate).to eq 100
    end

    it 'uses base weekly price if daily nil' do
      base_rate['PROP_RATE_NIGHTLY_FROM'] = nil
      base_rate['PROP_RATE_MONTHLY_FROM'] = '3000.00'

      subject = described_class.new(base_rate, periodical_rates)
      expect(subject.nightly_rate).to eq 100
    end

    context 'base rate without data' do
      let(:base_rate) { {} }
      it { expect(subject.nightly_rate).to eq 23.46 }
    end
  end

end