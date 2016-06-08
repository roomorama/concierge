require "spec_helper"

RSpec.describe AtLeisure::Booking do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) { double(username: "roomorama", password: "atleisure-roomorama", test_mode: "Yes") }
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

  before do
    allow_any_instance_of(API::Support::JSONRPC).to receive(:request_id) { 888888888888 }
  end

  subject { described_class.new(credentials) }
  
  describe "#book" do
    let(:endpoint) { AtLeisure::Booking::ENDPOINT }

    it "returns the underlying network error if any happened" do
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      result = subject.book(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it "returns an error result in case unrecognized response" do
      stub_with_fixture("atleisure/unrecognized.json")
      result = subject.book(params)

      expect(result).to_not be_success
      expect(result.error.code).to eq :unrecognised_response
    end

    it "returns a reservation booking code according to the response" do
      stub_with_fixture("atleisure/booking_success.json")
      expected_code = "175607953"
      result        = subject.book(params)

      expect(result).to be_success
      reservation = result.value

      expect(reservation).to be_a Reservation
      expect(reservation.code).to eq expected_code
    end

    def stub_with_fixture(name)
      atleisure_response = JSON.parse(read_fixture(name))
      response           = {
        id:     888888888888,
        result: atleisure_response
      }.to_json

      stub_call(:post, endpoint) { [200, {}, response] }
    end
  end
end
