require 'spec_helper'

RSpec.describe AtLeisure::PropertyValidation do
  include Support::Fixtures

  describe '#valid?' do
    let(:today) { Date.new(2016, 6, 18) }

    %w(on_request_property property_with_mandatory_cost not_found
       property_with_not_actual_availabilities hotel mill tent_lodge).each do |failed_data|
      it "fails with #{failed_data}" do
        validation = described_class.new(build_property(failed_data), today)
        expect(validation.valid?).to be false
      end
    end

    it 'returns successful result' do
      validation = described_class.new(build_property('property_data'), today)
      expect(validation.valid?).to be true
    end

  end

  private

  def build_property(fixture)
    JSON.parse(read_fixture("atleisure/#{fixture}.json"))
  end

end