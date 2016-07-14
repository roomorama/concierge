require "spec_helper"

RSpec.describe Concierge::SafeAccessHash do

  let(:hash) { Hash[a: :b, c: { d: 'value', '@strange key' => { deep_key: 'deepest value' } }] }

  subject { described_class.new(hash) }

  it "behaves like hash with indifferent access" do
    expect(subject[:a]).to eq :b
    expect(subject['a']).to eq :b
    expect(subject['c'][:d]).to eq 'value'
    expect(subject[:c]['d']).to eq 'value'
  end

  it "does not modify the original hash" do
    subject
    expect(hash[:c][:d]).to eq "value"
  end

  describe "#get" do
    it "returns value without throwing exception" do
      expect(subject.get('a')).to eq :b
      expect(subject.get('c.@strange key.deep_key')).to eq 'deepest value'
      expect(subject.get('c.unknown_key.one_more_key')).to be nil
    end

    it "returns nil for not existing keys" do
      expect(subject.get('c.d.va')).to be_nil
    end
  end

  it "should be equal to another instance if the underlying hashes are the same" do
    other = described_class.new(hash)
    expect(subject == other).to eq true
  end

  describe "#missing_keys_from" do

    subject { described_class.new(hash).missing_keys_from(test_keys) }

    context "when everything is present" do
      let(:test_keys) { ["a", "c.d", "c.@strange key.deep_key"] }
      it { expect(subject).to eq [] }
    end

    context "when some keys are not found" do
      let(:test_keys) { ["a", "some.new_key", "some.other.new.key"] }
      it { expect(subject).to eq ["some.new_key", "some.other.new.key"] }
    end
  end

  describe "#merge" do

    subject { described_class.new(hash).merge({test: "val"}) }

    it { expect { subject }.to_not change{hash.keys.count} }
    it { expect(subject["test"]).to eq "val" }
  end

end
