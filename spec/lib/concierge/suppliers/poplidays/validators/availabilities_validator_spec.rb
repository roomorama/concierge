require 'spec_helper'

RSpec.describe Poplidays::Validators::AvailabilitiesValidator do

  describe '#valid?' do
    let(:availabilities_stub) { {'availabilities' => [1, 2, 3]} }

    it 'returns true for all valid' do
      allow_any_instance_of(Poplidays::Validators::AvailabilityValidator).to receive(:valid?).and_return(true, true, true)
      validator = described_class.new(availabilities_stub, double)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false if all availabilities invalid' do
      allow_any_instance_of(Poplidays::Validators::AvailabilityValidator).to receive(:valid?).and_return(false, false, false)
      validator = described_class.new(availabilities_stub, double)
      expect(validator.valid?).to be_falsey
    end

    it 'returns true if at least one is valid' do
      allow_any_instance_of(Poplidays::Validators::AvailabilityValidator).to receive(:valid?).and_return(false, true, false)
      validator = described_class.new(availabilities_stub, double)
      expect(validator.valid?).to be_falsey
    end
  end
end