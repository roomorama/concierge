require 'spec_helper'

RSpec.describe Kigo::Mappers::PropertyType do
  include Support::Fixtures

  let(:property_types) { JSON.parse(read_fixture('kigo/property_types.json')) }

  subject { described_class.new(property_types) }

  describe '#map' do
    let(:property_type_id) { 4 }

    it { expect(subject.map(123)).to eq nil }
    it { expect(subject.map(nil)).to eq nil }
    it { expect(subject.map(property_type_id)).to eq ['house', nil] }

  end

end
