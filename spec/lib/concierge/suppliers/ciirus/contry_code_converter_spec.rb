require 'spec_helper'

RSpec.describe Ciirus::CountryCodeConverter do

  subject { described_class.new }

  describe '#code_by_name' do
    it 'returns code for custom cases' do
      code = subject.code_by_name('UK')
      expect(code).to eq('GB')
    end

    it 'returns code for alpha2 input' do
      code = subject.code_by_name('US')
      expect(code).to eq('US')
      code = subject.code_by_name('RU')
      expect(code).to eq('RU')
    end

    it 'returns code for alpha3 input' do
      code = subject.code_by_name('ALA')
      expect(code).to eq('AX')
      code = subject.code_by_name('ALB')
      expect(code).to eq('AL')
    end

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
  end
end
