require "spec_helper"

RSpec.describe SAW::Importer do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest

  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }

  describe "fetch_properties_by_countries" do
    it "returns an empty array when all requests are failed / empty" do
      mock_request(:country, :multiple)
      mock_request(:propertysearch, :empty)
    
      countries_result = subject.fetch_countries
      properties = subject.fetch_properties_by_countries(countries_result.value)
      expect(properties.size).to eq(0)
    end

    it "returns a result with array of all properties from all countries" do
      mock_request(:propertysearch, :success)
      mock_request(:country, :multiple)

      countries_result = subject.fetch_countries
      properties = subject.fetch_properties_by_countries(countries_result.value)
      expect(properties.size).to eq(20)
    end
  end
end
