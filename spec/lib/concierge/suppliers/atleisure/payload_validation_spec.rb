require 'spec_helper'

RSpec.describe AtLeisure::PayloadValidation do
  include Support::Fixtures

  describe '#valid?' do

    let(:payload) { JSON.parse read_fixture('atleisure/property_data.json') }
    let(:property_type_number) { 10 }
    generic_keys = %w(HouseCode BasicInformationV3 MediaV2 LanguagePackENV4 PropertiesV1 LayoutExtendedV2 AvailabilityPeriodV1 CostsOnSiteV1)

    generic_keys.each do |key|
      it "fails with missing #{key} key" do
        payload.delete(key)
        validation = described_class.new(payload)

        expect(Concierge.context).to receive(:augment)
        expect(validation.valid?).to be false
      end
    end

    it { expect(payload['MediaV2']).to be_an Array }

    it 'fails with wrong images structure' do
      payload['MediaV2'].first.delete('TypeContents')
      validation = described_class.new(payload)

      expect(validation.valid?).to be false
    end

    it 'fails without property type parameter' do
      payload['PropertiesV1'].delete_if { |item| item['TypeNumber'] == property_type_number }
      validation = described_class.new(payload)

      expect(validation.valid?).to be false
    end

    it 'is success' do
      validation = described_class.new(payload)

      expect(Concierge.context).to_not receive(:augment)
      expect(validation.valid?).to be true
    end
  end
end