require "spec_helper"

RSpec.describe SAW::Commands::CountriesFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest

  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }

  it "returns results with an array of countries" do
    mock_request(:country, :multiple)

    results = subject.call
    countries = results.value

    expect(results.success?).to be true
    expect(countries.size).to eq(4)
    expect(countries.map {|c| { id: c.id, name: c.name }}).to eq([
      { id: "1", name: "United States" },
      { id: "2", name: "Canada" },
      { id: "3", name: "Brazil" },
      { id: "4", name: "France" },
    ])
  end
  
  it "returns results when there is only one country" do
    mock_request(:country, :one)

    results = subject.call
    countries = results.value

    expect(results.success?).to be true
    expect(countries.size).to eq(1)
    expect(countries.map {|c| { id: c.id, name: c.name }}).to eq([
      { id: "1", name: "United States" }
    ])
  end
      
  it "returns an empty array when there is no countries" do
    mock_request(:country, :empty)

    results = subject.call
    countries = results.value
    
    expect(results.success?).to be true
    expect(countries.size).to eq(0)
  end
      
  it "returns failure result when SAW API returns an error" do
    mock_request(:country, :error)
    
    results = subject.call
    countries = results.value
    
    expect(results.success?).to be false
    expect(countries).to be_nil
  end
  
  context "when response from the SAW api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      mock_bad_xml_request(:country)

      result = subject.call
    
      expect(result.success?).to be false
      expect(result.error.code).to eq(:unrecognised_response)
    end
  end
end
