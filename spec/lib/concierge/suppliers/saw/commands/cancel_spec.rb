require "spec_helper"

RSpec.describe SAW::Commands::Cancel do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest
  include Support::SAW::LastContextEvent

  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }
  let(:reference_number) { "MTA66591" }

  it "successfully cancels the reservation" do
    mock_request(:bookingcancellation, :success)

    result = subject.call(reference_number)
    expect(result).to be_success
    expect(result.value).to eq(reference_number)
  end

  context "when response from the SAW api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      mock_bad_xml_request(:bookingcancellation)

      result = subject.call(reference_number)

      expect(result).not_to be_success
      expect(result.error.code).to eq(:unrecognised_response)
      expect(result.error.data).to be_nil
      expect(last_context_event[:message]).to eq(
        "Error response could not be recognised (no `code` or `description` fields)."
      )
      expect(last_context_event[:backtrace]).to be_kind_of(Array)
      expect(last_context_event[:backtrace].any?).to be true
    end
  end

  context "when booking is not allowed (already booked)" do
    it "returns a result with an appropriate error" do
      mock_request(:bookingcancellation, :not_allowed)

      result = subject.call(reference_number)

      expect(result).not_to be_success
      expect(result.error.code).to eq("9008")
      expect(result.error.data).to eq(
        "Booking cancellation is not allowed for this booking."
      )
      expect(last_context_event[:message]).to eq(
        "Response indicating the error `9008`, and description `Booking cancellation is not allowed for this booking.`"
      )
      expect(last_context_event[:backtrace]).to be_kind_of(Array)
      expect(last_context_event[:backtrace].any?).to be true
    end
  end

  context "when incorrect booking_ref_number is provided" do
    it "returns a result with an appropriate error" do
      mock_request(:bookingcancellation, :invalid_tag)

      result = subject.call(reference_number)

      expect(result).not_to be_success
      expect(result.error.code).to eq("9007")
      expect(result.error.data).to eq(
        "The valid booking_ref_number tag is not supplied"
      )
      expect(last_context_event[:message]).to eq(
        "Response indicating the error `9007`, and description `The valid booking_ref_number tag is not supplied`"
      )
      expect(last_context_event[:backtrace]).to be_kind_of(Array)
      expect(last_context_event[:backtrace].any?).to be true
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      mock_timeout_error(:bookingcancellation)

      result = subject.call(reference_number)

      expect(result).not_to be_success
      expect(last_context_event[:message]).to eq("timeout")
      expect(result.error.code).to eq :connection_timeout
      expect(result.error.data).to be_nil
    end
  end
end
