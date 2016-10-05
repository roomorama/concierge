require "spec_helper"

RSpec.describe RentalsUnited::Commands::LocationsFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:supplier_name) { RentalsUnited::Client::SUPPLIER_NAME }
  let(:credentials) { Concierge::Credentials.for(supplier_name) }
  let(:url) { credentials.url }

  context "when location does not exist" do
    let(:location_ids) { ["9998"] }
    let(:subject) { described_class.new(credentials, location_ids) }

    it "returns error" do
      stub_data = read_fixture("rentals_united/locations/locations.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_locations
      expect(result).not_to be_success
      expect(result.error.code).to eq(:unknown_location)
    end
  end

  context "when fetching location for neighborhood" do
    let(:location_ids) { ["9999"] }
    let(:subject) { described_class.new(credentials, location_ids) }

    it "fetches and returns one location" do
      stub_data = read_fixture("rentals_united/locations/locations.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_locations
      expect(result).to be_success
      expect(result.value.size).to eq(1)

      location = result.value.first
      expect(location).to be_kind_of(RentalsUnited::Entities::Location)
      expect(location.id).to eq("9999")
      expect(location.city).to eq("Paris")
      expect(location.region).to eq("Ile-de-France")
      expect(location.country).to eq("France")
      expect(location.neighborhood).to eq("Neighborhood")
    end

    context "when parent location does not exist" do
      it "returns error" do
        stub_data = read_fixture("rentals_united/locations/no_parent_for_neighborhood.xml")
        stub_call(:post, url) { [200, {}, stub_data] }

        result = subject.fetch_locations
        expect(result).not_to be_success
        expect(result.error.code).to eq(:unknown_location)
      end
    end
  end

  context "when fetching location for city" do
    let(:location_ids) { ["1505"] }
    let(:subject) { described_class.new(credentials, location_ids) }

    it "fetches and returns one location" do
      stub_data = read_fixture("rentals_united/locations/locations.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_locations
      expect(result).to be_success
      expect(result.value.size).to eq(1)

      location = result.value.first
      expect(location).to be_kind_of(RentalsUnited::Entities::Location)
      expect(location.id).to eq("1505")
      expect(location.city).to eq("Paris")
      expect(location.region).to eq("Ile-de-France")
      expect(location.country).to eq("France")
    end

    context "when parent location does not exist" do
      it "returns error" do
        stub_data = read_fixture("rentals_united/locations/no_parent_for_city.xml")
        stub_call(:post, url) { [200, {}, stub_data] }

        result = subject.fetch_locations
        expect(result).not_to be_success
        expect(result.error.code).to eq(:unknown_location)
      end
    end
  end

  context "when fetching location for region" do
    let(:location_ids) { ["10351"] }
    let(:subject) { described_class.new(credentials, location_ids) }

    it "fetches and returns one location" do
      stub_data = read_fixture("rentals_united/locations/locations.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_locations
      expect(result).to be_success
      expect(result.value.size).to eq(1)

      location = result.value.first
      expect(location).to be_kind_of(RentalsUnited::Entities::Location)
      expect(location.id).to eq("10351")
      expect(location.city).to eq(nil)
      expect(location.region).to eq("Ile-de-France")
      expect(location.country).to eq("France")
    end

    context "when parent location does not exist" do
      it "returns error" do
        stub_data = read_fixture("rentals_united/locations/no_parent_for_region.xml")
        stub_call(:post, url) { [200, {}, stub_data] }

        result = subject.fetch_locations
        expect(result).not_to be_success
        expect(result.error.code).to eq(:unknown_location)
      end
    end
  end

  context "when fetching location for country" do
    let(:location_ids) { ["20"] }
    let(:subject) { described_class.new(credentials, location_ids) }

    it "fetches and returns one location" do
      stub_data = read_fixture("rentals_united/locations/locations.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_locations
      expect(result).to be_success
      expect(result.value.size).to eq(1)

      location = result.value.first
      expect(location).to be_kind_of(RentalsUnited::Entities::Location)
      expect(location.id).to eq("20")
      expect(location.city).to eq(nil)
      expect(location.region).to eq(nil)
      expect(location.country).to eq("France")
    end

    context "when parent location does not exist" do
      it "returns location anyway" do
        stub_data = read_fixture("rentals_united/locations/no_parent_for_country.xml")
        stub_call(:post, url) { [200, {}, stub_data] }

        result = subject.fetch_locations
        expect(result).not_to be_success
        expect(result.error.code).to eq(:unknown_location)
      end
    end
  end

  context "when response from the api has error status" do
    let(:location_ids) { ["1505"] }
    let(:subject) { described_class.new(credentials, location_ids) }

    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/locations/error_status.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_locations

      expect(result).not_to be_success
      expect(result.error.code).to eq("9999")

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq(
        "Response indicating the Status with ID `9999`, and description ``"
      )
      expect(event[:backtrace]).to be_kind_of(Array)
      expect(event[:backtrace].any?).to be true
    end
  end

  context "when response from the api is not well-formed xml" do
    let(:location_ids) { ["1505"] }
    let(:subject) { described_class.new(credentials, location_ids) }

    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/bad_xml.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_locations

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
    let(:location_ids) { ["1505"] }
    let(:subject) { described_class.new(credentials, location_ids) }

    it "returns a result with an appropriate error" do
      stub_call(:post, url) { raise Faraday::TimeoutError }

      result = subject.fetch_locations

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
