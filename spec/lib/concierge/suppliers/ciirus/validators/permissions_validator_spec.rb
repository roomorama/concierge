require 'spec_helper'

RSpec.describe Ciirus::Validators::PermissionsValidator do

  let(:property_without_booking) { double(online_booking_allowed: false, time_share: false)}
  let(:timeshare_property) { double(online_booking_allowed: true, time_share: true)}
  let(:valid_permissions) { double(online_booking_allowed: true, time_share: false)}

  describe '#valid?' do
    it 'returns true for valid permissions' do
      validator = described_class.new(valid_permissions)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false when online booking forbidden' do
      validator = described_class.new(property_without_booking)
      expect(validator.valid?).to be_falsey
    end

    it 'returns false for timeshare property' do
      validator = described_class.new(timeshare_property)
      expect(validator.valid?).to be_falsey
    end
  end
end
