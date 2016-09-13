require 'spec_helper'

RSpec.describe Poplidays::Validators::PropertyValidator do

  let(:on_request_property) { {'requestOnly' => true} }
  let(:valid_property) { {'requestOnly' => false} }

  describe '#valid?' do
    it 'returns true for valid property' do
      validator = described_class.new(valid_property)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for on request property' do
      validator = described_class.new(on_request_property)
      expect(validator.valid?).to be_falsey
    end
  end
end