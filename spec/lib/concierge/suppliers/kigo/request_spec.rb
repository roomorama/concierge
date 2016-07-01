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
      result = nil

      expect {
        result = subject.build_compute_pricing(params)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_property_id

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "generic_message"
    end
  end

  describe "#build_reservation_details" do
    let(:params) {
      {
        property_id: "123",
        check_in:    "2016-03-22",
        check_out:   "2016-03-24",
        guests:      2,
        customer:    {
          first_name:   "Alex",
          last_name:    "Black",
          email:        "alex@black.com",
          phone_number: "123-123",
          country:      "RU"
        }
      }
    }

    it "builds the computePricing parameters for the Kigo Real Page API" do
      result = subject.build_reservation_details(params)

      expect(result).to be_success
      expect(result.value).to eq({
        "PROP_ID"        => 123,
        "RES_CHECK_IN"   => "2016-03-22",
        "RES_CHECK_OUT"  => "2016-03-24",
        "RES_N_ADULTS"   => 2,
        "RES_COMMENT"    => "Booking made via Roomorama on #{Date.today}",
        "RES_N_CHILDREN" => 0,
        "RES_GUEST"      => {
          "RES_GUEST_EMAIL"     => "alex@black.com",
          "RES_GUEST_PHONE"     => "123-123",
          "RES_GUEST_COUNTRY"   => "RU",
          "RES_GUEST_LASTNAME"  => "Black",
          "RES_GUEST_FIRSTNAME" => "Alex"
        }
      })
    end

    it "fails if the property ID is not numerical" do
      params[:property_id] = "KG-123"
      result               = nil

      expect {
        result = subject.build_compute_pricing(params)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_property_id

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "generic_message"
    end
  end


end
