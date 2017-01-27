require 'spec_helper'

RSpec.describe Avantio::Validators::PropertyValidator do

  let(:invalid_properties) do
    [
      double(master_kind_code: '3', bedrooms: 2), # Hotel
      double(master_kind_code: '2', bedrooms: nil), # Unknown bedrooms count
    ]
  end
  let(:valid_property) do
    double(master_kind_code: '2', bedrooms: 2)
  end

  describe '#valid?' do
    it 'returns true for valid property' do
      validator = described_class.new(valid_property)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for invalid properties' do
      invalid_properties.each do |property|
        validator = described_class.new(property)
        expect(validator.valid?).to be_falsey
      end
    end
  end

  describe '#error_message' do
    let(:error_message) { described_class.new(property).error_message }

    context "unknown bedrooms count" do
      let(:property) { double(master_kind_code: '2', bedrooms: nil) }
      it { expect(error_message).to eq "Number of bedrooms not given." }
    end

    context "unsupported property type" do
      let(:property) { double(master_kind_code: '3', bedrooms: 3) }
      it { expect(error_message).to eq "Property of type Garage/Parking or Hotel is not supported." }
    end

    context "both unknown bedrooms and unsupported type" do
      let(:property) { double(master_kind_code: '3', bedrooms: nil) }
      it { expect(error_message).to eq "Property of type Garage/Parking or Hotel is not supported.\nNumber of bedrooms not given." }
    end
  end
end
