require 'spec_helper'

RSpec.describe Ciirus::Validators::PermissionsValidator do

  let(:invalid_cases) do
    [
      double(online_booking_allowed: false, time_share: false, aoa_property: false, deleted: false),
      double(online_booking_allowed: true, time_share: true, aoa_property: false, deleted: false),
      double(online_booking_allowed: true, time_share: false, aoa_property: true, deleted: false),
      double(online_booking_allowed: true, time_share: false, aoa_property: false, deleted: true)
    ]
  end
  let(:valid_permissions) do
    double(online_booking_allowed: true,
           time_share: false,
           aoa_property: false,
           deleted: false
    )
  end

  describe '#valid?' do
    it 'returns false for invalid cases' do
      invalid_cases.each do |p|
        validator = described_class.new(p)
        expect(validator.valid?).to be_falsey
      end
    end

    it 'returns true for valid permissions' do
      validator = described_class.new(valid_permissions)
      expect(validator.valid?).to be_truthy
    end
  end
end
