require "spec_helper"

RSpec.describe Kigo::RequestBuilder do

  describe "#compute_pricing" do
    let(:params) {
      { property_id: "123", check_in: "2016-03-04", check_out: "2016-03-12", guests: 4 }
    }

    it "builds the computePricing parameters for the Kigo Real Page API" do
      result = subject.compute_pricing(params)

      expect(result).to be_success
      expect(result.value).to eq({
        "PROP_ID"        => 123,
        "RES_CHECK_IN"   => "2016-03-04",
        "RES_CHECK_OUT"  => "2016-03-12",
        "RES_N_ADULTS"   => 4,
        "RES_N_CHILDREN" => 0
      })
    end

    it "fails if the property ID is not numerical" do
      params[:property_id] = "KG-123"
      result = subject.compute_pricing(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_property_id
    end
  end

end
