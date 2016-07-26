require 'spec_helper'

RSpec.describe Ciirus::Importer do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://example.org')
  end
  let(:property_id) { 10 }

  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }

  subject { described_class.new(credentials) }

  shared_examples 'handling errors' do
    it 'returns an unsuccessful result if external call fails' do
      allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }

      expect(result).to be_a(Result)
      expect(result).to_not be_success
      expect(result.error.code).to eq :savon_error
    end
  end

  shared_examples 'success response' do
    it 'returns a success data' do
      stub_call(method: method, response: response)

      expect(result).to be_a(Result)
      expect(result).to be_success
    end
  end

  describe '#fetch_properties' do
    let(:method) { Ciirus::Commands::PropertiesFetcher::OPERATION_NAME }
    let(:response) { read_fixture('ciirus/responses/properties_response.xml') }
    let(:result) { subject.fetch_properties }

    it_behaves_like 'success response'
    it_behaves_like 'handling errors'
  end

  describe '#fetch_images' do
    let(:method) { Ciirus::Commands::ImageListFetcher::OPERATION_NAME }
    let(:response) { read_fixture('ciirus/responses/image_list_response.xml') }
    let(:result) { subject.fetch_images(property_id) }

    it_behaves_like 'success response'
    it_behaves_like 'handling errors'
  end

  describe '#fetch_rates' do
    let(:method) { Ciirus::Commands::PropertyRatesFetcher::OPERATION_NAME }
    let(:response) { read_fixture('ciirus/responses/property_rates_response.xml') }
    let(:result) { subject.fetch_rates(property_id) }

    it_behaves_like 'success response'
    it_behaves_like 'handling errors'
  end

  describe '#fetch_reservations' do
    let(:method) { Ciirus::Commands::ReservationsFetcher::OPERATION_NAME }
    let(:response) { read_fixture('ciirus/responses/reservations_response.xml') }
    let(:result) { subject.fetch_reservations(property_id) }

    it_behaves_like 'success response'
    it_behaves_like 'handling errors'
  end

  describe '#fetch_security_deposit' do
    let(:wsdl) { read_fixture('ciirus/additional_wsdl.xml') }
    let(:method) { Ciirus::Commands::SecurityDepositFetcher::OPERATION_NAME }
    let(:response) { read_fixture('ciirus/responses/extras_response.xml') }
    let(:result) { subject.fetch_security_deposit(property_id) }

    it_behaves_like 'success response'
    it_behaves_like 'handling errors'
  end

  describe '#fetch_description' do
    let(:result) { subject.fetch_description(property_id) }
    let(:response) { read_fixture('ciirus/responses/descriptions_plain_text_response.xml') }
    let(:html_response) { read_fixture('ciirus/responses/descriptions_html_response.xml') }
    let(:empty_response) { read_fixture('ciirus/responses/empty_descriptions_plain_text_response.xml') }

    it_behaves_like 'handling errors'

    it 'returns plain text description if it exists' do
      stub_call(method: Ciirus::Commands::DescriptionsPlainTextFetcher::OPERATION_NAME,
                response: response)
      expect_any_instance_of(Ciirus::Commands::DescriptionsPlainTextFetcher).to receive(:call).once.and_call_original
      expect_any_instance_of(Ciirus::Commands::DescriptionsHtmlFetcher).to_not receive(:call)
      result = subject.fetch_description(property_id)

      expect(result).to be_a(Result)
      expect(result).to be_success
    end

    it 'returns html description if plain text is blank' do
      stub_call(method: Ciirus::Commands::DescriptionsPlainTextFetcher::OPERATION_NAME,
                response: empty_response)
      stub_call(method: Ciirus::Commands::DescriptionsHtmlFetcher::OPERATION_NAME,
                response: html_response)
      expect_any_instance_of(Ciirus::Commands::DescriptionsHtmlFetcher).to receive(:call).once.and_call_original
      expect_any_instance_of(Ciirus::Commands::DescriptionsPlainTextFetcher).to receive(:call).once.and_call_original
      result = subject.fetch_description(property_id)

      expect(result).to be_a(Result)
      expect(result).to be_success
    end

    describe '#fetch_permissions' do
      let(:method) { Ciirus::Commands::PropertyPermissionsFetcher::OPERATION_NAME }
      let(:response) { read_fixture('ciirus/responses/property_permissions_response.xml') }
      let(:result) { subject.fetch_permissions(property_id) }

      it_behaves_like 'success response'
      it_behaves_like 'handling errors'
    end

  end
end