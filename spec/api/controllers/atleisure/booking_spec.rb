require 'spec_helper'
require_relative "../shared/booking_validations"


RSpec.describe API::Controllers::AtLeisure::Booking do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:endpoint) { AtLeisure::Booking::ENDPOINT }
  let(:params) {
    {
        property_id: "A123",
        unit_id: "xxx",
        check_in: "2016-03-22",
        check_out: "2016-03-24",
        guests: 2,
        customer: {
            first_name: "Alex",
            last_name: "Black",
            country: "India",
            city: "Mumbai",
            address: "first street",
            postal_code: "123123",
            email: "test@example.com",
            phone: "555-55-55",
        }
    }
  }

  it_behaves_like "performing booking parameters validations", controller_generator: -> { described_class.new }


  describe "#call" do

    before do
      allow_any_instance_of(API::Support::JSONRPC).to receive(:request_id) { 888888888888 }
      stub_call(:post, endpoint) { [200, {}, jsonrpc_fixture(fixture)] }
    end

    let(:response) { parse_response(described_class.new.call(params)) }

    context "fail" do
      let(:fixture) { "atleisure/unrecognized.json" }

      it "returns an error message" do

        expect(response.status).to eq 503
        expect(response.body["status"]).to eq "error"
        expect(response.body["errors"]["booking"]).to eq "Could not create booking with remote supplier"
      end
    end

    context "success" do
      let(:fixture) { "atleisure/booking_success.json" }
      let(:expected_code) { "175607953" } # from fixture

      it "returns a booking code" do
        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 200
        expect(response.body["status"]).to eq "ok"
        expect(response.body["code"]).to eq expected_code
      end
    end
  end

  def parse_response(rack_response)
    Support::ResponseWrapper.new(
        rack_response[0],
        rack_response[1],
        JSON.parse(rack_response[2].first)
    )
  end

  def jsonrpc_fixture(name)
    {
        id: 888888888888,
        result: JSON.parse(read_fixture(name))
    }.to_json
  end

end
