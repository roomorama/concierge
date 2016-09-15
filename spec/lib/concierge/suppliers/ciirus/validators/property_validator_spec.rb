require 'spec_helper'

RSpec.describe Ciirus::Validators::PropertyValidator do

  let(:invalid_cases) do
    [
      double(type: 'Unspecified', xco: 23.234, yco: 45.2553, main_image_url: 'http://image.org/1'),
      double(type: 'Motel', xco: 0, yco: 0, main_image_url: 'http://image.org/1'),
      double(type: 'Motel', xco: 23.234, yco: 34.2344, main_image_url: 'http://images.ciirus.com/properties/37961/105836/images/ccpdemo1.jpg')
    ]
  end
  let(:valid_property) { double(type: 'Motel', xco: 0, yco: 45.2553, main_image_url: 'http://image.org/1')}

  describe '#valid?' do
    it 'returns true for valid property' do
      validator = described_class.new(valid_property)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for invalid cases' do
      invalid_cases.each do |property|
        validator = described_class.new(property)
        expect(validator.valid?).to be_falsey
      end
    end
  end
end
