require 'spec_helper'

RSpec.describe AtLeisure::Mapper do
  include Support::Fixtures

  let(:layout_items) { JSON.parse(read_fixture('atleisure/layout_items.json')) }
  let(:properties_data) { JSON.parse(read_fixture('atleisure/properties_data.json')) }

  subject { described_class.new(layout_items: layout_items) }

  describe '#prepare' do
    let(:property_data) { properties_data.first }
    let(:invalid_data) { properties_data.last }

    it 'returns the result with roomorama property accordingly provided data' do
      result = subject.prepare(property_data)

      expect(result).to be_success

      property = result.value

      expect(property).to be_a Roomorama::Property
    end
  end

end