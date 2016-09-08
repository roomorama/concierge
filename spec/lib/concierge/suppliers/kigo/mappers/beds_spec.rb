require 'spec_helper'

RSpec.describe Kigo::Mappers::Beds do

  let(:bed_type_ids) { (1..15).to_a }

  subject { described_class.new(bed_type_ids) }

  it { expect(subject.single_beds_size).to eq 8 }
  it { expect(subject.double_beds_size).to eq 3 }
  it { expect(subject.sofa_beds_size).to eq 3 }

  it 'returns proper double beds size' do
    mapper = described_class.new([3, 4, 4, 15])

    expect(mapper.double_beds_size).to eq 1
    expect(mapper.single_beds_size).to eq 2
    expect(mapper.sofa_beds_size).to eq 1
  end

  it 'doubles single beds with proper ids' do
    twice_single_bed_ids = [13, 14]
    mapper = described_class.new(twice_single_bed_ids)

    expect(mapper.single_beds_size).to eq 4
  end
end