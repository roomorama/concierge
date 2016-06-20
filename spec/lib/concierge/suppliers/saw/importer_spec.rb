require "spec_helper"
require "pry"

RSpec.describe SAW::Importer do
  include Support::HTTPStubbing
  include Support::Fixtures
  

  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }

  it "returns an empty array when all requests are failed / empty" do
    mock_request(:country, :multiple)
    mock_request(:propertysearch, :empty)
  
    countries_result = subject.fetch_countries
    properties = subject.fetch_properties_by_countries(countries_result.value)
    expect(properties.size).to eq(0)
  end

  describe "fetch_properties_by_countries" do
    it "returns a result with array of all properties from all countries" do
      mock_request(:propertysearch, :success)
      mock_request(:country, :multiple)

      countries_result = subject.fetch_countries
      properties = subject.fetch_properties_by_countries(countries_result.value)
      expect(properties.size).to eq(20)
    end
  end
  
  private
  def mock_request(endpoint, filename)
    stub_data = read_fixture("saw/#{endpoint}/#{filename}.xml")
    stub_call(:post, endpoint_for(endpoint)) { [200, {}, stub_data] }
  end

  def endpoint_for(method)
    "http://staging.servicedapartmentsworldwide.net/xml/#{method}.aspx"
  end
end
