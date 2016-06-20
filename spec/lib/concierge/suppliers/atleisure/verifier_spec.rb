require 'spec_helper'

RSpec.describe AtLeisure::Verifier do
  include Support::Fixtures

  subject { described_class.new }

  describe '#verify' do

    it 'fails if property availabilities on request only' do
      property = build_property('on_request_property')
      expect(subject.verify(property)).to be false
    end

    it 'fails if the property has mandatory costs' do
      property = build_property('property_with_mandatory_cost')
      expect(subject.verify(property)).to be false
    end

    it 'fails if property was not found' do
      property = build_property('not_found')
      expect(subject.verify(property)).to be false
    end

    it 'returns successful result' do
      property = build_property('property_data')
      expect(subject.verify(property)).to be true
    end

  end

  private

  def build_property(fixture)
    JSON.parse(read_fixture("atleisure/#{fixture}.json"))
  end

end