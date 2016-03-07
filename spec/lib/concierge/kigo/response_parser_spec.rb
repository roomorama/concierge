require "spec_helper"

RSpec.describe Kigo::ResponseParser do
  include Support::Fixtures

  let(:request_params) {
    { property_id: "123", check_in: "2016-04-05", check_out: "2016-04-08", guests: 1 }
  }

  describe "#compute_pricing" do
    it "fails if the API response does not indicate success" do
      response = read_fixture("kigo/e_nosuch.json")
      result = subject.compute_pricing(request_params, response)

      expect(result).not_to be_success
      expect(result.error.code).to eq :quote_call_failed
    end

    it "fails if the API returns an invalid JSON response" do
      result = subject.compute_pricing(request_params, "invalid-json")

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it "fails without a reply field" do
      response = read_fixture("kigo/no_api_reply.json")
      result = subject.compute_pricing(request_params, response)

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
    end

    it "fails if there is no currency, fees or total fields" do
      response = read_fixture("kigo/no_total.json")
      result = subject.compute_pricing(request_params, response)

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
    end

    it "is unavailable if the API indicates so" do
      response = read_fixture("kigo/unavailable.json")
      result = subject.compute_pricing(request_params, response)

      expect(result).to be_success
      quotation = result.value
      expect(quotation).to be_a Quotation
      expect(quotation.available).to eq false
    end

    it "returns a quotation with the returned information on success" do
      response = read_fixture("kigo/success.json")
      result = subject.compute_pricing(request_params, response)

      expect(result).to be_success
      quotation = result.value
      expect(quotation).to be_a Quotation
      expect(quotation.property_id).to eq "123"
      expect(quotation.check_in).to eq "2016-04-05"
      expect(quotation.check_out).to eq "2016-04-08"
      expect(quotation.guests).to eq 1
      expect(quotation.available).to eq true
      expect(quotation.currency).to eq "EUR"
      expect(quotation.fee).to eq 0
      expect(quotation.total).to eq 570
    end
  end
end
