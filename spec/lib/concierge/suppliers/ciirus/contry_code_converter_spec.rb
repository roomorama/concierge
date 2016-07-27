require 'spec_helper'

RSpec.describe Ciirus::CountryCodeConverter do

  subject { described_class.new }

  describe '#code_by_name' do
    it 'returns code for custom cases' do
      code = subject.code_by_name('UK')
      expect(code.value).to eq('GB')
    end

    it 'returns code for alpha2 input' do
      code = subject.code_by_name('US')
      expect(code.value).to eq('US')
      code = subject.code_by_name('RU')
      expect(code.value).to eq('RU')
    end

    it 'returns code for alpha3 input' do
      code = subject.code_by_name('ALA')
      expect(code.value).to eq('AX')
      code = subject.code_by_name('ALB')
      expect(code.value).to eq('AL')
    end

    it 'returns code for country name input' do
      code = subject.code_by_name('Hungary')
      expect(code.value).to eq('HU')
      code = subject.code_by_name('Mexico')
      expect(code.value).to eq('MX')
      code = subject.code_by_name('United States of America')
      expect(code.value).to eq('US')
    end

    it 'returns nil for unknown input' do
      code = subject.code_by_name('dsfe')
      expect(code.value).to be_nil
    end

    it 'returns nil for nil input' do
      code = subject.code_by_name(nil)
      expect(code.value).to be_nil
    end
  end
end
