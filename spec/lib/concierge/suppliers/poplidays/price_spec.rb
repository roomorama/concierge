require "spec_helper"

RSpec.describe Poplidays::Price do
  include Support::Fixtures
  include Support::HTTPStubbing
  include Support::Factories

  let!(:supplier) { create_supplier(name: Poplidays::Client::SUPPLIER_NAME) }
  let!(:host) { create_host(supplier_id: supplier.id, fee_percentage: 5) }
  let(:params) {
    { property_id: '3498', check_in: '2016-12-17', check_out: '2016-12-26', guests: 2 }
  }
  let(:credentials) do
    double(url: 'api.poplidays.com',
           client_key: '1111',
           passphrase: '4311')
  end
  let(:quote_response) do
    '{
      "value": 3410.28,
      "ruid": "09cdecc64b5ba9504c08bb598075262f"
    }'
  end

  let(:unavailable_quote_response) do
    '{
      "code": 400,
      "message": "Unauthorized arriving day",
      "ruid": "76b95928b4fec0ca2dc6ddb33e89b044"
    }'
  end

  subject { described_class.new(credentials) }

  describe '#quote' do
    let(:property_details_endpoint) { 'https://api.poplidays.com/v2/lodgings/3498' }
    let(:quote_endpoint) { 'https://api.poplidays.com/v2/bookings/easy' }

    it 'returns the underlying network error if any happened in the call for the property endpoint' do
      stub_call(:get, property_details_endpoint) { raise Faraday::TimeoutError }
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it 'fails if host is not found' do
      allow(subject).to receive(:fetch_host) { nil }
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :host_not_found
    end

    it 'returns the underlying network error if any happened in the call for the quote endpoint' do
      stub_with_fixture(property_details_endpoint, 'poplidays/property_details.json')
      stub_call(:post, quote_endpoint) { raise Faraday::TimeoutError }

      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it 'does not recognise the property details reponse without mandatory services declaration' do
      stub_with_fixture(property_details_endpoint, 'poplidays/property_details_missing_mandatory_services.json')

      result = nil

      expect {
        result = subject.quote(params)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :unrecognised_response

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq 'response_mismatch'
    end

    it 'does not recognise the response if it returns an XML body instead' do
      stub_with_fixture(property_details_endpoint, 'poplidays/unexpected_xml_response.xml')
      result = subject.quote(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it 'returns an error in case the property is on request' do
      stub_with_fixture(property_details_endpoint, 'poplidays/property_details_on_request.json')
      result = nil

      expect {
        result = subject.quote(params)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_property_error

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq 'response_mismatch'
    end

    it 'returns an error in case the property price disabled' do
      stub_with_fixture(property_details_endpoint, 'poplidays/property_details_price_disabled.json')
      result = nil

      expect {
        result = subject.quote(params)
      }.to change { Concierge.context.events.size }

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_property_error

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq 'response_mismatch'
    end

    [400, 409].each do |status|
      it "returns an unavailable quotation for poplidays response with #{status} status" do
        stub_with_fixture(property_details_endpoint, 'poplidays/property_details.json')
        stub_call(:post, quote_endpoint) { [status, {}, unavailable_quote_response] }
        result = subject.quote(params)

        expect(result).to be_success
        quotation = result.value

        expect(quotation).to be_a Quotation
        expect(quotation.available).to eq false
        expect(quotation.property_id).to eq '3498'
        expect(quotation.check_in).to eq '2016-12-17'
        expect(quotation.check_out).to eq '2016-12-26'
        expect(quotation.guests).to eq 2
        expect(quotation.currency).to be_nil
        expect(quotation.total).to be_nil
      end
    end

    it "returns not success result for poplidays response with 500 status" do
      stub_with_fixture(property_details_endpoint, 'poplidays/property_details.json')
      stub_call(:post, quote_endpoint) { [500, {}, unavailable_quote_response] }
      result = subject.quote(params)

      expect(result).not_to be_success
    end

    it 'returns an available quotation properly priced according to the response' do
      stub_call(:post, quote_endpoint) { [200, {}, quote_response] }
      stub_with_fixture(property_details_endpoint, 'poplidays/property_details.json')

      result = subject.quote(params)

      expect(result).to be_success
      quotation = result.value

      expect(quotation).to be_a Quotation
      expect(quotation.available).to eq true
      expect(quotation.property_id).to eq '3498'
      expect(quotation.check_in).to eq '2016-12-17'
      expect(quotation.check_out).to eq '2016-12-26'
      expect(quotation.guests).to eq 2
      expect(quotation.currency).to eq 'EUR'
      expect(quotation.host_fee_percentage).to eq 5
      expect(quotation.total).to eq 3410.28 + 25 # rental + mandatory services
    end

    def stub_with_fixture(endpoint, name)
      poplidays_response = read_fixture(name)
      stub_call(:get, endpoint) { [200, {}, poplidays_response] }
    end
  end
end
