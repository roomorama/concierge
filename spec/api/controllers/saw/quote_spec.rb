require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::SAW::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::Factories
  include Support::SAW::MockRequest

  let(:supplier) { create_supplier(name: SAW::Client::SUPPLIER_NAME) }
  let(:host) { create_host(fee_percentage: 7.0, supplier_id: supplier.id) }
  let(:property) { create_property(identifier: "567", host_id: host.id) }

  let(:params) do
    {
      property_id: property.identifier,
      unit_id: '10612',
      check_in: "2015-02-26",
      check_out: "2015-02-28",
      guests: 2
    }
  end

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like "external error reporting" do
    let(:supplier_name) { "SAW" }

    def provoke_failure!
      mock_timeout_error(:propertyrates)
      Struct.new(:code).new("connection_timeout")
    end
  end

  let(:controller) { described_class.new }

  shared_examples_for "a case for unavailable quotation" do
    it "is a success" do
      result = controller.quote_price(params)
      expect(result.success?).to be true
      expect(result).to be_kind_of(Result)
    end

    it "holds a quotation" do
      result = controller.quote_price(params)
      quotation = result.value
      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.property_id).to eq(params[:property_id])
      expect(quotation.unit_id).to eq(params[:unit_id])
      expect(quotation.check_in).to eq(params[:check_in])
      expect(quotation.check_out).to eq(params[:check_out])
      expect(quotation.guests).to eq(params[:guests])
      expect(quotation.available).to be false
    end
  end

  it "performs successful request returning Quotation object" do
    mock_request(:propertyrates, :success)

    result = controller.quote_price(params)

    expect(result.success?).to be true
    expect(result).to be_kind_of(Result)
    expect(result.value).not_to be nil

    quotation = result.value
    expect(quotation).to be_kind_of(Quotation)
    expect(quotation.property_id).to eq(params[:property_id])
    expect(quotation.unit_id).to eq(params[:unit_id])
    expect(quotation.check_in).to eq(params[:check_in])
    expect(quotation.check_out).to eq(params[:check_out])
    expect(quotation.guests).to eq(params[:guests])
    expect(quotation.total).to eq(641.3)
    expect(quotation.currency).to eq('EUR')
    expect(quotation.available).to be true
  end

  context "when unit is not bookable" do
    before { mock_request(:propertyrates, :not_bookable_unit) }
    it_should_behave_like "a case for unavailable quotation"
  end

  context "when property is on request only" do
    it "returns a quotation with an appropriate error" do
      mock_request(:propertyrates, :request_only)

      result = controller.quote_price(params)

      expect(result.success?).to be false
      expect(result).to be_kind_of(Result)
      expect(result.value).to be nil
    end
  end

  context "when given wrong currency" do
    it "returns a quotation with an appropriate error" do
      mock_request(:propertyrates, :currency_error)

      result = controller.quote_price(params)

      expect(result.success?).to be false
      expect(result).to be_kind_of(Result)
      expect(result.value).to be nil
    end
  end

  context "when property has no available rates" do
    before { mock_request(:propertyrates, :rates_not_available) }
    it_should_behave_like "a case for unavailable quotation"
  end

  context "when response from the SAW api is not well-formed xml" do
    it "returns a quotation with an appropriate error" do
      mock_bad_xml_request(:propertyrates)

      result = controller.quote_price(params)

      expect(result.success?).to be false
      expect(result).to be_kind_of(Result)
      expect(result.value).to be nil
    end
  end

  context "when there is multiple available units" do
    it "performs successful request returning Quotation object for selected unit" do
      params[:unit_id] = "9733"
      mock_request(:propertyrates, :success_multiple_units)

      result = controller.quote_price(params)
      expect(result.success?).to be true
      expect(result).to be_kind_of(Result)
      expect(result.value).not_to be nil

      quotation = result.value
      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.total).to eq(72.25)
      expect(quotation.currency).to eq('EUR')
      expect(quotation.available).to be true

      params[:unit_id] = "9734"
      result = controller.quote_price(params)
      expect(result.success?).to be true
      expect(result).to be_kind_of(Result)
      expect(result.value).not_to be nil

      quotation = result.value
      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.total).to eq(170)
      expect(quotation.currency).to eq('EUR')
      expect(quotation.available).to be true
    end
  end

  context "when there is no rates for given unit" do
    before do
      params[:unit_id] = "1111"
      mock_request(:propertyrates, :success_multiple_units)
    end

    it_should_behave_like "a case for unavailable quotation"
  end

  context "when there is rates, but it's not available" do
    before { mock_request(:propertyrates, :no_allocation) }
    it_should_behave_like "a case for unavailable quotation"
  end
end
