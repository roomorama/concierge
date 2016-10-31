require "spec_helper"

RSpec.shared_examples "quote call" do
  include Concierge::Errors::Quote
  subject { described_class.new.call(params) }

  context "client returns network_error" do
    it "returns a generic error message" do
      expect_any_instance_of(described_class).to receive(:quote_price).and_return(Result.error(:network_error))
      response = parse_response(subject)
      expect(response.status).to eq 503
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["quote"]).to eq "Could not quote price with remote supplier"
    end
  end

  context "client returns check_in_too_near" do
    it "returns proper error messages if client returns check_in_too_near" do
      expect_any_instance_of(described_class).to receive(:quote_price).and_return(check_in_too_near)
      response = parse_response(subject)
      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["quote"]).to eq "Selected check-in date is too near"
    end
  end

  context "client returns check_in_too_far" do
    it "returns proper error messages" do
      expect_any_instance_of(described_class).to receive(:quote_price).and_return(check_in_too_far)
      response = parse_response(subject)
      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["quote"]).to eq "Selected check-in date is too far"
    end
  end

  context "client returns stay_too_short" do
    it "returns proper error messages" do
      expect_any_instance_of(described_class).to receive(:quote_price).and_return(stay_too_short(15))
      response = parse_response(subject)
      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["quote"]).to eq "The minimum number of nights to book this apartment is 15"
    end
  end

  it "returns unavailable quotation" do
    unavailable_quotation = Quotation.new({
      property_id: params[:property_id],
      check_in:    params[:check_in],
      check_out:   params[:check_out],
      guests:      params[:guests],
      available:   false
    })
    expect_any_instance_of(described_class).to receive(:quote_price).and_return(Result.new(unavailable_quotation))
    response = parse_response(subject)
    expect(response.status).to eq 200
    expect(response.body["status"]).to eq "ok"
    expect(response.body["available"]).to eq false
    expect(response.body["property_id"]).to eq params[:property_id]
    expect(response.body["check_in"]).to eq params[:check_in]
    expect(response.body["check_out"]).to eq params[:check_out]
    expect(response.body["guests"]).to eq params[:guests]
    expect(response.body).not_to have_key("currency")
    expect(response.body).not_to have_key("total")
  end

  it "returns available quotation when call is successful" do
    available_quotation = Quotation.new({
        property_id:         params[:property_id],
        check_in:            params[:check_in],
        check_out:           params[:check_out],
        guests:              params[:guests],
        available:           true,
        currency:            "EUR",
        total:               56.78,
        host_fee_percentage: 7.0,
        host_fee:            3.71 ,
        net_rate:            53.07,
      })
    expect_any_instance_of(described_class).to receive(:quote_price).and_return(Result.new(available_quotation))

    response = parse_response(subject)
    expect(response.status).to eq 200
    expect(response.body["status"]).to eq "ok"
    expect(response.body["available"]).to eq true
    expect(response.body["property_id"]).to eq params[:property_id]
    expect(response.body["check_in"]).to eq params[:check_in]
    expect(response.body["check_out"]).to eq params[:check_out]
    expect(response.body["guests"]).to eq params[:guests]
    expect(response.body["currency"]).to eq "EUR"
    expect(response.body["total"]).to eq 56.78
    expect(response.body["net_rate"]).to eq 53.07
    expect(response.body["host_fee"]).to eq 3.71
    expect(response.body["host_fee_percentage"]).to eq 7.0
  end
end

