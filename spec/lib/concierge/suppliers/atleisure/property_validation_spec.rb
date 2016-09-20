require 'spec_helper'

RSpec.describe AtLeisure::PropertyValidation do
  include Support::Fixtures

  let(:today) { Date.new(2016, 6, 18) }
  before do
    allow(Date).to receive(:today).and_return(Date.new(2016, 6, 18))
  end

  describe '#valid?' do
    %w(on_request_property property_with_mandatory_cost not_found
       property_with_not_actual_availabilities hotel mill tent_lodge).each do |failed_data|
      it "fails with #{failed_data}" do
        validation = described_class.new(build_property(failed_data))
        expect(validation.valid?).to be false
      end
    end

    it 'returns successful result' do
      validation = described_class.new(build_property('property_data'))
      expect(validation.valid?).to be true
    end

  end

  private

  def build_property(fixture)
    JSON.parse(read_fixture("atleisure/#{fixture}.json"))
  end

end