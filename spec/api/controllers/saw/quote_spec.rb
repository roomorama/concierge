require "spec_helper"

RSpec.describe API::Controllers::SAW::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest
  
  let(:request_params) do
    {
      property_id: 1,
      unit_id: 10612,
      check_in: "2015-02-26",
      check_out: "2015-02-28",
      num_guests: 2,
    }
  end

  let(:controller) { described_class.new }
  
  it "performs successful request returning Quotation object" do
    mock_request(:propertyrates, :success)

    quotation = controller.quote_price(request_params)

    expect(quotation.successful?).to be true
    expect(quotation).to be_kind_of(Quotation)
    expect(quotation.total).to eq(641.3)
    expect(quotation.currency).to eq('EUR')
  end
      
  context "when property is on request only" do
    it "returns a quotation with an appropriate error" do
      mock_request(:propertyrates, :request_only)

      quotation = controller.quote_price(request_params)

      expect(quotation.successful?).to be false
      expect(quotation.errors[:quote]).to eq(
        "Could not quote price with remote supplier"
      )
    end
  end

  context "when given wrong currency" do
    it "returns a quotation with an appropriate error" do
      mock_request(:propertyrates, :currency_error)
      
      quotation = controller.quote_price(request_params)

      expect(quotation.successful?).to be false
      expect(quotation.errors[:quote]).to eq(
        "Could not quote price with remote supplier"
      )
    end
  end

  context "when property has no available rates" do
    it "returns a quotation with an appropriate error" do
      mock_request(:propertyrates, :rates_not_available)

      quotation = controller.quote_price(request_params)
      
      expect(quotation.successful?).to be false
      expect(quotation.errors[:quote]).to eq(
        "Could not quote price with remote supplier"
      )
    end
  end

  context "when response from the SAW api is not well-formed xml" do
    it "returns a quotation with an appropriate error" do
      mock_bad_xml_request(:propertyrates)

      quotation = controller.quote_price(request_params)
      
      expect(quotation.successful?).to be false
      expect(quotation.errors[:quote]).to eq(
        "Could not quote price with remote supplier"
      )
    end
  end

  context "when there is multiple available units" do
    it "performs successful request returning Quotation object for selected unit" do
      request_params[:unit_id] = "9733"
      mock_request(:propertyrates, :success_multiple_units)

      quotation = controller.quote_price(request_params)

      expect(quotation.successful?).to be true
      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.total).to eq(72.25)
      expect(quotation.currency).to eq('EUR')
      
      request_params[:unit_id] = "9734"
      quotation = controller.quote_price(request_params)
      expect(quotation.successful?).to be true
      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.total).to eq(170)
      expect(quotation.currency).to eq('EUR')
    end
  end
end
