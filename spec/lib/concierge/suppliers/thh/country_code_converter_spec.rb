require 'spec_helper'

RSpec.describe THH::CountryCodeConverter do

  subject { described_class.new }

  describe '#code_by_name' do

    it 'returns code for country name input' do
      code = subject.code_by_name('Hungary')
      expect(code).to eq('HU')
      code = subject.code_by_name('Mexico')
      expect(code).to eq('MX')
      code = subject.code_by_name('United States of America')
      expect(code).to eq('US')
    end

    it 'returns nil for unknown input' do
      code = subject.code_by_name('dsfe')
      expect(code).to be_nil
    end

    it 'returns nil for nil input' do
      code = subject.code_by_name(nil)
      expect(code).to be_nil
    end
  end
end
