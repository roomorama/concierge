require "spec_helper"

RSpec.describe SAW::Commands::DetailedPropertyFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest

  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }

  it "returns detailed property object" do
    mock_request(:propertydetail, :success)

    result = subject.call(1) 
    expect(result.success?).to be true
    
    detailed_property = result.value
    expect(detailed_property).to be_kind_of(SAW::Entities::DetailedProperty)
  end
  
  it "returns result with error after error" do
    mock_request(:propertydetail, :error)

    result = subject.call(1) 
    expect(result.success?).to be false
  end
end
