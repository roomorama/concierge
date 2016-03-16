require "spec_helper"

RSpec.describe Concierge::SafeAccessHash do

  let(:hash) { Hash[a: :b, c: { d: 'value', '@strange key' => { deep_key: 'deepest value' } }] }

  subject { described_class.new(hash) }

  it 'behaves like hash with indifferent access' do
    expect(subject[:a]).to eq :b
    expect(subject['a']).to eq :b
    expect(subject['c'][:d]).to eq 'value'
    expect(subject[:c]['d']).to eq 'value'
  end

  describe '#get' do

    it 'returns value without throwing exception' do
      expect(subject.get('a')).to eq :b
      expect(subject.get('c.@strange key.deep_key')).to eq 'deepest value'
      expect(subject.get('c.unknown_key.one_more_key')).to be nil
    end

  end
end