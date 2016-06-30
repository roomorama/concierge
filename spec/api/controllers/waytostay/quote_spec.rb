require "spec_helper"
require "concierge/result"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::Waytostay::Quote do
  include Support::HTTPStubbing

  let(:params) {
    { property_id: "567", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
  }

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like "external error reporting" do
    let(:params) {
      { property_id: "321", unit_id: "123", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
    }
    let(:supplier_name) { "Waytostay" }
    let(:error_code) { "savon_erorr" }

    def provoke_failure!
      # Timesout with trying to get token
      allow_any_instance_of(OAuth2::Client).to receive(:get_token) { raise Faraday::TimeoutError }
      Struct.new(:code).new("connection_timeout")
    end
  end

  describe "#call" do
    subject { described_class.new.call(params) }

    it "returns a proper error message if client returns quotation with error" do
      expect_any_instance_of(Waytostay::Client).to receive(:quote).and_return(Result.error(:network_error))

      response = parse_response(subject)
      expect(response.status).to eq 503
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["quote"]).to eq "Could not quote price with remote supplier"
    end

    it "returns unavailable quotation when client returns so" do
      unavailable_quotation = Quotation.new({
        property_id: params[:property_id],
        check_in:    params[:check_in],
        check_out:   params[:check_out],
        guests:      params[:guests],
        available:   false
      })
      expect_any_instance_of(Waytostay::Client).to receive(:quote).and_return(Result.new(unavailable_quotation))

      response = parse_response(subject)
      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "ok"
      expect(response.body["available"]).to eq false
      expect(response.body["property_id"]).to eq "567"
      expect(response.body["check_in"]).to eq "2016-03-22"
      expect(response.body["check_out"]).to eq "2016-03-25"
      expect(response.body["guests"]).to eq 2
      expect(response.body).not_to have_key("currency")
      expect(response.body).not_to have_key("total")
    end

    it "returns available quotation when call is successful" do
      available_quotation = Quotation.new({
          property_id: params[:property_id],
          check_in:    params[:check_in],
          check_out:   params[:check_out],
          guests:      params[:guests],
          available:   true,
          currency:    "EUR",
          total:       56.78,
        })
      expect_any_instance_of(Waytostay::Client).to receive(:quote).and_return(Result.new(available_quotation))

      response = parse_response(subject)
      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "ok"
      expect(response.body["available"]).to eq true
      expect(response.body["property_id"]).to eq "567"
      expect(response.body["check_in"]).to eq "2016-03-22"
      expect(response.body["check_out"]).to eq "2016-03-25"
      expect(response.body["guests"]).to eq 2
      expect(response.body["currency"]).to eq "EUR"
      expect(response.body["total"]).to eq 56.78

    end
  end

end
