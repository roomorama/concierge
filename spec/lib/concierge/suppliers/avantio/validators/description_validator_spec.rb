require 'spec_helper'

RSpec.describe Avantio::Validators::DescriptionValidator do

  let(:invalid_description) { double(images: [])}
  let(:valid_description) { double(images: ['image.org/1'])}

  describe '#valid?' do
    it 'returns true for valid' do
      validator = described_class.new(valid_description)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for invalid' do
      validator = described_class.new(invalid_description)
      expect(validator.valid?).to be_falsey
    end
  end
end
