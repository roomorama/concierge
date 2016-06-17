require "spec_helper"
require "pry"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::SAW::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures
  
  let(:request_params) do
    {
      property_id: 1,
      unit_id: 10612,
      check_in: "2015-02-26",
      check_out: "2015-02-28",
      num_guests: 2,
      currency_code: "USD"
    }
  end

  let(:controller) { described_class.new }
  
  it "performs successful request returning Quotation object" do
    mock_request(:propertyrates, :success)

    result = controller.quote_price(request_params)

    expect(result.successful?).to be true
    expect(result).to be_kind_of(Quotation)
    expect(result.total).to eq(641)
    expect(result.currency).to eq('EUR')
  end
      
  context "when property is on request only" do
    it "returns a result with appropriate error" do
      mock_request(:propertyrates, :request_only)

      result = controller.quote_price(request_params)

      expect(result.successful?).to be false
      expect(result.errors[:quote]).to eq(
        "Could not quote price with remote supplier"
      )
    end
  end

  context "when given wrong currency" do
    it "returns a result with appropriate error" do
      mock_request(:propertyrates, :currency_error)
      
      result = controller.quote_price(request_params)

      expect(result.successful?).to be false
      expect(result.errors[:quote]).to eq(
        "Could not quote price with remote supplier"
      )
    end
  end

  context "when property has no available rates" do
    it "returns a result with appropriate error" do
      mock_request(:propertyrates, :rates_not_available)

      result = controller.quote_price(request_params)
      
      expect(result.successful?).to be false
      expect(result.errors[:quote]).to eq(
        "Could not quote price with remote supplier"
      )
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
