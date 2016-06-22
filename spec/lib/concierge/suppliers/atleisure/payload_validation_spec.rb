require 'spec_helper'

RSpec.describe AtLeisure::PayloadValidation do
  include Support::Fixtures

  describe '#valid?' do

    let(:payload) { JSON.parse read_fixture('atleisure/property_data.json') }

    it 'fails with missing keys' do
      payload.delete('MediaV2')
      validation = described_class.new(payload)

      expect(validation).to receive(:augment_context).with(['MediaV2'])
      expect(validation.valid?).to be false
    end

    it 'fails with missing keys' do
      validation = described_class.new(payload)

      expect(validation.valid?).to be true
    end
  end
end