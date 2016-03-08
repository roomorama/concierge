require "spec_helper"

RSpec.describe Kigo::Request do
  let(:credentials) { double(subscription_key: "deadbeef") }
  subject { described_class.new(credentials) }

  describe "#base_uri" do
    it "points to Kigo Channels API" do
      expect(subject.base_uri).to eq "https://www.kigoapis.com"
    end
  end

  describe "#endpoint_for" do
    it "returns the Channels API endpoint for a given method" do
      expect(subject.endpoint_for("someMethod")).to eq "/channels/v1/someMethod?subscription-key=deadbeef"
    end
  end

  describe "#build_compute_pricing" do
    let(:params) {
      { property_id: "123", check_in: "2016-03-04", check_out: "2016-03-12", guests: 4 }
    }

    it "builds the computePricing parameters for the Kigo Real Page API" do
      result = subject.build_compute_pricing(params)

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
      result = subject.build_compute_pricing(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_property_id
    end
  end

end
