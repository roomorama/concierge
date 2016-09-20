require "spec_helper"

RSpec.describe AtLeisure::Booking do
  include Support::Fixtures
  include Support::HTTPStubbing
  include Support::Factories

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
    allow_any_instance_of(Concierge::JSONRPC).to receive(:request_id) { 888888888888 }
  end

  subject { described_class.new(credentials) }

  describe "#fetch" do
    let(:endpoint) { AtLeisure::Booking::FETCH_ENDPOINT }

    before { stub_with_fixture("atleisure/details_of_one_booking_v1.json", endpoint) }

    it "contains guest info" do
      result = subject.fetch(975669885)
      expect(result).to be_success
      expect(result.value["NumberOfAdults"]).to eq 1
      expect(result.value["ArrivalTimeFrom"]).to eq "15:00"
      expect(result.value["ArrivalTimeUntil"]).to eq "18:00"
      expect(result.value["DepartureTimeFrom"]).to eq "09:00"
      expect(result.value["DepartureTimeUntil"]).to eq "10:00"
      expect(result.value["BookingDate"]).to eq "2016-09-12"
      expect(result.value["CustomerSurname"]).to eq "Somesurname"
    end
  end

  describe "#book" do
    let(:endpoint) { AtLeisure::Booking::ENDPOINT }

    it "returns the underlying network error if any happened" do
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      result = subject.book(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it "returns an error result in case unrecognized response" do
      stub_with_fixture("atleisure/unrecognized.json", endpoint)
      result = subject.book(params)

      expect(result).to_not be_success
      expect(result.error.code).to eq :unrecognised_response
    end

    it "returns a reservation booking code according to the response, and enqueue pdf worker" do
      expect(subject).to receive(:enqueue_pdf_worker) do |reservation|
        expect(reservation.attachment_url).to eq "https://s3"
      end

      stub_with_fixture("atleisure/booking_success.json", endpoint)
      expected_code = "175607953"
      result        = subject.book(params)

      expect(result).to be_success
      reservation = result.value

      expect(reservation).to be_a Reservation
      expect(reservation.reference_number).to eq expected_code
    end

    context "reservation details" do

      let(:expected_reservation_details) {
        {
          "HouseCode"                => "A123",
          "ArrivalDate"              => "2016-03-22",
          "DepartureDate"            => "2016-03-24",
          "NumberOfAdults"           => 2,
          "WebsiteRentPrice"         => 300,
          "CustomerSurname"          => "Black",
          "CustomerInitials"         => "Alex",
          "CustomerTelephone1Number" => "555-55-55",
          "BookingOrOption"          => "Booking",
          "CustomerEmail"            => "atleisure@roomorama.com",
          "CustomerCountry"          => "SG",
          "CustomerLanguage"         => "EN",
          "NumberOfChildren"         => 0,
          "NumberOfBabies"           => 0,
          "NumberOfPets"             => 0,
          "Test"                     => "Yes",
          "WebpartnerCode"           => "roomorama",
          "WebpartnerPassword"       => "atleisure-roomorama"
        }
      }

      it "sends correct reservation details to partner" do

        expect_any_instance_of(Concierge::JSONRPC).to receive(:invoke).
          with("PlaceBookingV1", expected_reservation_details).
          and_return(Result.new('any'))

        subject.book(params)
      end
    end
  end

  describe "#enqueue_pdf_worker" do
    it "adds a valid operation to sqs" do
      expect_any_instance_of(Concierge::Queue).to receive(:add) do |queue, op|
        expect{op.validate!}.to_not raise_error
      end
      subject.send(:enqueue_pdf_worker, create_reservation(attachment_url: "https://asdf"))
    end
  end

  def stub_with_fixture(name, endpoint)
    atleisure_response = JSON.parse(read_fixture(name))
    response           = {
      id:     888888888888,
      result: atleisure_response
    }.to_json

    stub_call(:post, endpoint) { [200, {}, response] }
  end
end
