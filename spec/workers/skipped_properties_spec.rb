require "spec_helper"

RSpec.describe Workers::SkippedProperties do

  describe '#add' do
    it 'adds skipped property' do
      subject.add('prop1', 'some reason')
      expect(subject.to_a).to eq (
        [
          {
            'reason' => 'some reason',
            'ids' => ['prop1']
          }
        ]
      )
    end

    it 'adds several skipped properties' do
      subject.add('prop1', 'some reason')
      subject.add('prop2', 'another reason')
      expect(subject.to_a).to eq (
         [
           {
             'reason' => 'some reason',
             'ids' => ['prop1']
           },
           {
             'reason' => 'another reason',
             'ids' => ['prop2']
           },
         ]
       )
    end

    it 'adds several skipped properties with the same reason' do
      subject.add('prop1', 'some reason')
      subject.add('prop2', 'some reason')
      expect(subject.to_a).to eq (
         [
           {
             'reason' => 'some reason',
             'ids' => ['prop1', 'prop2']
           }
         ]
       )
    end
  end

  describe '#skipped?' do

    it 'returns true for skipped property' do
      subject.add('prop1', 'some reason')
      subject.add('prop2', 'some reason')
      expect(subject.skipped?('prop1')).to be true
    end

    it 'returns false for non skipped properties' do
      subject.add('prop1', 'some reason')
      subject.add('prop2', 'some reason')
      expect(subject.skipped?('prop3')).to be false
    end

    it 'returns false for non skipped properties' do
      expect(subject.skipped?('prop3')).to be false
    end
  end

  describe '#to_a' do
    it 'returns empty list when empty' do
      expect(subject.to_a).to eq([])
    end
  end
end
