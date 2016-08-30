require 'spec_helper'

RSpec.describe Kigo::PayloadValidation do
  include Support::Fixtures

  let(:payload) { JSON.parse read_fixture('kigo/property_data.json') }

  describe '#valid?' do
    let(:invalid_property_type) { 13 }

    it { expect(described_class.new(payload)).to be_valid }

    it 'is invalid for non ib property' do
      payload['PROP_INSTANT_BOOK'] = false

      subject = described_class.new(payload)

      expect(subject).not_to be_valid
    end

    it 'is invalid for hotel property' do
      payload['PROP_INFO']['PROP_TYPE_ID'] = invalid_property_type

      subject = described_class.new(payload)

      expect(subject).not_to be_valid
    end

    context 'kigo legacy' do
      it 'is invalid for non ib property' do
        subject = described_class.new(payload, ib_flag: false)

        expect(subject).not_to be_valid
      end
    end
  end
end