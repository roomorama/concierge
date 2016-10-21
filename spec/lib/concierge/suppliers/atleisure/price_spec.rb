require "spec_helper"

RSpec.describe AtLeisure::Price do
  include Support::Fixtures
  include Support::HTTPStubbing
  include Support::Factories

  let(:credentials) { double(username: "roomorama", password: "atleisure-roomorama") }
  let(:supplier) { create_supplier(name: AtLeisure::Client::SUPPLIER_NAME) }
  let!(:host) { create_host(supplier_id: supplier.id, fee_percentage: 7.0) }
  let(:params) {
    { property_id: "AT-123", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
  }

  before do

    allow_any_instance_of(Concierge::JSONRPC).to receive(:request_id) { 888888888888 }
  end

  subject { described_class.new(credentials) }

  RSpec.shared_examples "handling network errors" do
    it "returns the underlying network error if any happened" do
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
      expect(result.error.data).to be_nil
    end

    it "returns the underlying JSON RPC client error if any happened" do
      stub_call(:post, endpoint) { [200, {}, "invalid-json"] }
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
      expect(result.error.data).to be_nil
    end
  end

  describe "#quote" do
    let(:endpoint) { AtLeisure::Price::ENDPOINT }

    it_behaves_like "handling network errors"

    it "does not recognise the response without an availability status" do
      stub_with_fixture("atleisure/no_availability.json")
      result = nil

      expect {
        result = subject.quote(params)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
      expect(result.error.data).to eq(
        "Could not determine if the property was available. The `Available` field was not given or has an invalid value."
      )

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "returns an error in case the property is on request" do
      stub_with_fixture("atleisure/on_request.json")
      result = nil

      expect {
        result = subject.quote(params)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :unsupported_on_request_reservation
      expect(result.error.data).to eq 'Instant booking is not supported for the given period'

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "does not recognise the response in case there is no price" do
      stub_with_fixture("atleisure/no_price.json")
      result = nil

      expect {
        result = subject.quote(params)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
      expect(result.error.data).to eq(
        "No price information could be retrieved. Searched fields `CorrectPrice` and `Price` and neither is given."
      )

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "returns an unavailable quotation in case the response indicates so" do
      stub_with_fixture("atleisure/unavailable.json")
      result = subject.quote(params)

      expect(result).to be_success
      quotation = result.value

      expect(quotation).to be_a Quotation
      expect(quotation.available).to eq false
      expect(quotation.property_id).to eq "AT-123"
      expect(quotation.check_in).to eq "2016-03-22"
      expect(quotation.check_out).to eq "2016-03-25"
      expect(quotation.guests).to eq 2
      expect(quotation.currency).to eq "EUR"
      expect(quotation.total).to be_nil
    end

    it "returns an available quotation properly priced according to the response" do
      create_property(identifier: "AT-123", host_id: host.id)
      stub_with_fixture("atleisure/available.json")
      result = subject.quote(params)

      expect(result).to be_success
      quotation = result.value

      expect(quotation).to be_a Quotation
      expect(quotation.available).to eq true
      expect(quotation.property_id).to eq "AT-123"
      expect(quotation.check_in).to eq "2016-03-22"
      expect(quotation.check_out).to eq "2016-03-25"
      expect(quotation.guests).to eq 2
      expect(quotation.currency).to eq "EUR"
      expect(quotation.total).to eq 150
      expect(quotation.host_fee_percentage).to eq(7)
    end

    def stub_with_fixture(name)
      atleisure_response = JSON.parse(read_fixture(name))
      response = {
        id: 888888888888,
        result: atleisure_response
      }.to_json

      stub_call(:post, endpoint) { [200, {}, response] }
    end
  end
end
