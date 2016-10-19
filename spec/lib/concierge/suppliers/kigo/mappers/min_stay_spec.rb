require 'spec_helper'

RSpec.describe Kigo::Mappers::MinStay do
  describe "#value" do
    it "selects property's minimum_stay if it's bigger than calendar's minimum_stay" do
      prop_min_stay = 20
      cal_min_stay  = 19

      min_stay_result = described_class.new(prop_min_stay, cal_min_stay).value
      expect(min_stay_result).to be_success
      expect(min_stay_result.value).to eq(20)
    end

    it "selects calendars's minimum_stay if it's bigger than property's minimum_stay" do
      prop_min_stay = 16
      cal_min_stay  = 17

      min_stay_result = described_class.new(prop_min_stay, cal_min_stay).value
      expect(min_stay_result).to be_success
      expect(min_stay_result.value).to eq(17)
    end

    it "selects any of minimum_stay values if they equal to each other" do
      prop_min_stay = 15
      cal_min_stay  = 15

      min_stay_result = described_class.new(prop_min_stay, cal_min_stay).value
      expect(min_stay_result).to be_success
      expect(min_stay_result.value).to eq(15)
    end

    it "selects property's minimum_stay when calendar's one is nil" do
      prop_min_stay = 13
      cal_min_stay  = nil

      min_stay_result = described_class.new(prop_min_stay, cal_min_stay).value
      expect(min_stay_result).to be_success
      expect(min_stay_result.value).to eq(13)
    end

    it "selects property's minimum_stay when calendar's one is nil" do
      prop_min_stay = nil
      cal_min_stay  = 11

      min_stay_result = described_class.new(prop_min_stay, cal_min_stay).value
      expect(min_stay_result).to be_success
      expect(min_stay_result.value).to eq(11)
    end

    it "applies .to_i to property's minimum_stay values" do
      prop_min_stay = "20"
      cal_min_stay  = 19

      min_stay_result = described_class.new(prop_min_stay, cal_min_stay).value
      expect(min_stay_result).to be_success
      expect(min_stay_result.value).to eq(20)
    end

    it "applies .to_i to calendars's minimum_stay values" do
      prop_min_stay = 10
      cal_min_stay  = "19"

      min_stay_result = described_class.new(prop_min_stay, cal_min_stay).value
      expect(min_stay_result).to be_success
      expect(min_stay_result.value).to eq(19)
    end

    it "returns error when both minimum_stay values are nil or 0" do
      null_values = [nil, 0]

      null_values.each do |prop_min_stay|
        null_values.each do |cal_min_stay|
          min_stay_result = described_class.new(prop_min_stay, cal_min_stay).value
          expect(min_stay_result).not_to be_success
          expect(min_stay_result.error.code).to eq(:invalid_min_stay)
          expect(min_stay_result.error.data).to eq(
            "Min stay was not defined both for property and calendar entry"
          )
        end
      end
    end
  end
end
