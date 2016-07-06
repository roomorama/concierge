require "spec_helper"

RSpec.describe SAW::Commands::DetailedPropertyFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest
  include Support::SAW::LastContextEvent

  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }
  let(:property_id) { 1 }

  it "returns detailed property object" do
    mock_request(:propertydetail, :success)

    result = subject.call(property_id) 
    expect(result.success?).to be true
    
    detailed_property = result.value
    expect(detailed_property).to be_kind_of(SAW::Entities::DetailedProperty)
  end
  
  it "returns result with error after error" do
    mock_request(:propertydetail, :error)

    result = subject.call(property_id) 
    expect(result.success?).to be false
      
    expect(result.error.code).to eq("0000")
    expect(last_context_event[:message]).to eq(
      "Response indicating the error `0000`, and description `Strange Error`"
    )
    expect(last_context_event[:backtrace]).to be_kind_of(Array)
    expect(last_context_event[:backtrace].any?).to be true
  end
  
  context "when response from the SAW api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      mock_bad_xml_request(:propertydetail)

      result = subject.call(property_id) 
    
      expect(result.success?).to be false
      expect(result.error.code).to eq(:unrecognised_response)
      expect(last_context_event[:message]).to eq(
        "Error response could not be recognised (no `code` or `description` fields)."
      )
      expect(last_context_event[:backtrace]).to be_kind_of(Array)
      expect(last_context_event[:backtrace].any?).to be true
    end
  end
  
  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      mock_timeout_error(:propertydetail)

      result = subject.call(property_id)

      expect(result).not_to be_success
      expect(last_context_event[:message]).to eq("timeout")
      expect(result.error.code).to eq :connection_timeout
    end
  end
end
