require "spec_helper"

# Just assertions that returned objects is correct-typed.
# Country attributes mapping specs are in corresponding Mapper class spec.
RSpec.describe SAW::Importer do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest

  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }

  describe "fetch_countries" do
    it "returns country objects" do
      mock_request(:country, :multiple)
      countries_result = subject.fetch_countries

      expect(countries_result.value).to all(be_kind_of(SAW::Entities::Country))
    end
  end
  
  describe "fetch_properties_by_country" do
    it "returns a result with an error if there is no results" do
      mock_request(:country, :one)
      mock_request(:propertysearch, :empty)
    
      countries_result = subject.fetch_countries
      current_country = countries_result.value.first

      properties_result = subject.fetch_properties_by_country(current_country)
      expect(properties_result.success?).to be false
      expect(properties_result.error.code).to eq("1007")
    end
  end

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
  
  describe "fetch_detailed_property" do
    let(:property_id) { 'fake' }

    it "returns a result with detailed property" do
      mock_request(:propertydetail, :success)
    
      property_result = subject.fetch_detailed_property(property_id)
      property = property_result.value

      expect(property).to be_kind_of(SAW::Entities::DetailedProperty)
    end
  end
end
