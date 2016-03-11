require "spec_helper"

RSpec.describe Poplidays::Price do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:params) {
    { property_id: "3498", check_in: "2016-12-17", check_out: "2016-12-26", guests: 2 }
  }

  describe "#quote" do
    let(:property_details_endpoint) { "https://api.poplidays.com/v2/lodgings/3498" }
    let(:calendar_endpoint) { "https://api.poplidays.com/v2/lodgings/3498/availabilities" }

    it "returns the underlying network error if any happened in the call for the calendar endpoint" do
      stub_call(:get, calendar_endpoint) { raise Faraday::TimeoutError }
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it "returns the underlying network error if any happened in the call for the property endpoint" do
      stub_with_fixture(calendar_endpoint, "poplidays/availabilities_calendar.json")
      stub_call(:get, property_details_endpoint) { raise Faraday::TimeoutError }

      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it "does not recognise the availabilities calendar response without availabilities" do
      stub_with_fixture(calendar_endpoint, "poplidays/availabilities_calendar_no_availabilities.json")
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
    end

    it "does not recognise the property details reponse without mandatory services declaration" do
      stub_with_fixture(calendar_endpoint, "poplidays/availabilities_calendar_no_availabilities.json")
      stub_with_fixture(property_details_endpoint, "poplidays/property_details_missing_mandatory_services.json")
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response
    end

    it "does not recognise the response if it returns an XML body instead" do
      stub_with_fixture(calendar_endpoint, "poplidays/unexpected_xml_response.xml")
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it "returns an error in case the property is on request" do
      stub_with_fixture(calendar_endpoint, "poplidays/availabilities_calendar.json")
      params[:check_in]  = "2016-05-04"
      params[:check_out] = "2016-05-11"
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :unsupported_on_request_property
    end

    it "returns an unavailable quotation in case there is no availability for the selected dates" do
      stub_with_fixture(calendar_endpoint, "poplidays/availabilities_calendar.json")
      params[:check_in]  = "2016-03-05"
      params[:check_out] = "2016-03-07"
      result = subject.quote(params)

      expect(result).to be_success
      quotation = result.value

      expect(quotation).to be_a Quotation
      expect(quotation.available).to eq false
      expect(quotation.property_id).to eq "3498"
      expect(quotation.check_in).to eq "2016-03-05"
      expect(quotation.check_out).to eq "2016-03-07"
      expect(quotation.guests).to eq 2
      expect(quotation.currency).to eq "EUR"
      expect(quotation.total).to be_nil
    end

    it "returns an available quotation properly priced according to the response" do
      stub_with_fixture(calendar_endpoint, "poplidays/availabilities_calendar.json")
      stub_with_fixture(property_details_endpoint, "poplidays/property_details.json")

      result = subject.quote(params)

      expect(result).to be_success
      quotation = result.value

      expect(quotation).to be_a Quotation
      expect(quotation.available).to eq true
      expect(quotation.property_id).to eq "3498"
      expect(quotation.check_in).to eq "2016-12-17"
      expect(quotation.check_out).to eq "2016-12-26"
      expect(quotation.guests).to eq 2
      expect(quotation.currency).to eq "EUR"
      expect(quotation.total).to eq 3638 + 25 # rental + mandatory services
    end

    def stub_with_fixture(endpoint, name)
      poplidays_response = read_fixture(name)
      stub_call(:get, endpoint) { [200, {}, poplidays_response] }
    end
  end
end
