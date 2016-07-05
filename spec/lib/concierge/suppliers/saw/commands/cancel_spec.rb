require "spec_helper"

RSpec.describe SAW::Commands::Cancel do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest

  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }
  let(:reservation_id) { "MTA66591" }

  it "successfully cancels the reservation" do
    mock_request(:bookingcancellation, :success)

    result = subject.call(reservation_id) 
    expect(result.success?).to be true
    expect(result.value).to eq(reservation_id)
  end
  
  context "when response from the SAW api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      mock_bad_xml_request(:bookingcancellation)

      result = subject.call(reservation_id) 
    
      expect(result.success?).to be false
      expect(result.error.code).to eq(:unrecognised_response)
    end
  end
  
  context "when booking is not allowed (already booked)" do
    it "returns a result with an appropriate error" do
      mock_request(:bookingcancellation, :not_allowed)

      result = subject.call(reservation_id) 
    
      expect(result.success?).to be false
      expect(result.error.code).to eq("9008")
    end
  end
  
  context "when incorrect booking_ref_number is provided" do
    it "returns a result with an appropriate error" do
      mock_request(:bookingcancellation, :invalid_tag)

      result = subject.call(reservation_id) 
    
      expect(result.success?).to be false
      expect(result.error.code).to eq("9007")
    end
  end
end
