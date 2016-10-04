require "spec_helper"

RSpec.describe RentalsUnited::Commands::Booking do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:supplier_name) { RentalsUnited::Client::SUPPLIER_NAME }
  let(:credentials) { Concierge::Credentials.for(supplier_name) }
  let(:reservation_params) do
    API::Controllers::Params::Booking.new(
      property_id: '1',
      check_in: '2016-02-02',
      check_out: '2016-02-03',
      guests: 1,
      currency_code: 'EUR',
      subtotal: '123.45',
      customer: {
        first_name: 'Test',
        last_name: 'User',
        email: 'testuser@example.com',
        phone: '111-222-3333',
        display: 'Test User'
      }
    )
  end
  let(:subject) { described_class.new(credentials, reservation_params) }

  it "successfully creates a reservation" do
    stub_data = read_fixture("rentals_united/reservations/success.xml")
    stub_call(:post, credentials.url) { [200, {}, stub_data] }

    result = subject.call
    expect(result.success?).to be true
    expect(result.value).to be_kind_of(Reservation)
    expect(result.value.reference_number).to eq("90377000")
    expect(result.value.property_id).to eq("1")
    expect(result.value.check_in).to eq("2016-02-02")
    expect(result.value.check_out).to eq("2016-02-03")
    expect(result.value.guests).to eq(1)
  end

  it "fails when property is not available for a given dates" do
    stub_data = read_fixture("rentals_united/reservations/not_available.xml")
    stub_call(:post, credentials.url) { [200, {}, stub_data] }

    result = subject.call
    expect(result).not_to be_success
    expect(result.error.code).to eq("1")

    event = Concierge.context.events.last.to_h
    expect(event[:message]).to eq(
      "Response indicating the Status with ID `1`, and description `Property is not available for a given dates`"
    )
    expect(event[:backtrace]).to be_kind_of(Array)
    expect(event[:backtrace].any?).to be true
  end

  context "when response from the api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/bad_xml.xml")
      stub_call(:post, credentials.url) { [200, {}, stub_data] }

      result = subject.call

      expect(result).not_to be_success
      expect(result.error.code).to eq(:unrecognised_response)

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq(
        "Error response could not be recognised (no `Status` tag in the response)"
      )
      expect(event[:backtrace]).to be_kind_of(Array)
      expect(event[:backtrace].any?).to be true
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      stub_call(:post, credentials.url) { raise Faraday::TimeoutError }

      result = subject.call

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
