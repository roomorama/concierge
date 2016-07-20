require 'spec_helper'
require_relative "../shared/booking_validations"


RSpec.describe API::Controllers::AtLeisure::Booking do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:endpoint) { AtLeisure::Booking::ENDPOINT }
  let(:params) {
    {
      property_id: "A123",
      check_in:    "2016-03-22",
      check_out:   "2016-03-24",
      guests:      2,
      subtotal:    300,
      customer:    {
        first_name:  "Alex",
        last_name:   "Black",
        country:     "India",
        city:        "Mumbai",
        address:     "first street",
        postal_code: "123123",
        email:       "test@example.com",
        phone:       "555-55-55",
      }
    }
  }

  it_behaves_like "performing booking parameters validations", controller_generator: -> { described_class.new }


  describe "#call" do

    before do
      allow_any_instance_of(Concierge::JSONRPC).to receive(:request_id) { 888888888888 }
    end

    let(:response) { parse_response(described_class.new.call(params)) }


    it "returns proper error if external request failed" do
      stub_call(:post, endpoint) { Faraday::ClientError }

      expect(response.status).to eq 503
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["booking"]).to eq "Could not create booking with remote supplier"
    end

    it "returns an error message with unrecognized response" do
      unrecognized_response = jsonrpc_fixture("atleisure/unrecognized.json")

      stub_call(:post, endpoint) { [200, {}, unrecognized_response] }

      expect(response.status).to eq 503
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["booking"]).to eq "Could not create booking with remote supplier"
    end

    it "creates external error record in database" do
      stub_call(:post, endpoint) { [200, {}, jsonrpc_fixture("atleisure/unrecognized.json")] }

      expect { parse_response(described_class.new.call(params)) }.to change {
        ExternalErrorRepository.count
      }.by(1)

      external_error = ExternalErrorRepository.first

      expect(external_error.operation).to eq "booking"
      expect(external_error.supplier).to eq "AtLeisure"
      expect(external_error.code).to eq "unrecognised_response"
    end

    it "returns a booking reference_number when successful booking" do
      success_response = jsonrpc_fixture("atleisure/booking_success.json")
      expected_reference_number    = "175607953" # from fixture

      stub_call(:post, endpoint) { [200, {}, success_response] }

      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "ok"
      expect(response.body["reference_number"]).to eq expected_reference_number
    end
  end


  def jsonrpc_fixture(name)
    {
      id:     888888888888,
      result: JSON.parse(read_fixture(name))
    }.to_json
  end

end
