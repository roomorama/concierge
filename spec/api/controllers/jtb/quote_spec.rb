require "spec_helper"
require_relative "../shared/multi_unit_quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::JTB::Quote do
  include Support::Fixtures

  it_behaves_like "performing multi unit parameter validations", controller_generator: -> { described_class.new }

  it_behaves_like "external error reporting" do
    let(:params) {
      { property_id: "321", unit_id: "123", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
    }
    let(:supplier_name) { "JTB" }
    let(:error_code) { "savon_erorr" }

    def provoke_failure!
      allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
      Struct.new(:code, :message).new("savon_error", "Savon::Error")
    end
  end

  describe "#call" do
    let(:params) {
      { property_id: "J123", unit_id: "123J", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
    }

    it "indicates the unit is unavailable in case there are no rate plans" do
      stub_quote(fixture: "jtb/unavailable_quote_response.json")

      response = parse_response(subject.call(params))
      expect(response.status).to eq 200

      expect(response.body["status"]).to eq "ok"
      expect(response.body["available"]).to eq false
      expect(response.body["property_id"]).to eq "J123"
      expect(response.body["check_in"]).to eq "2016-03-22"
      expect(response.body["check_out"]).to eq "2016-03-25"
      expect(response.body["guests"]).to eq 2
      expect(response.body).not_to have_key("currency")
      expect(response.body).not_to have_key("total")
    end

    it "fails if stay length more then 14 days" do
      params[:check_out] = "2016-04-10"
      response = parse_response(subject.call(params))

      expect(response.status).to eq 503
      
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]).to_not be_empty
    end
  end

  private

  def stub_quote(fixture:)
    allow_any_instance_of(JTB::Price).to receive(:remote_call) { Result.new(JSON.parse(read_fixture(fixture))) }
  end

  def parse_response(rack_response)
    Shared::QuoteResponse.new(
      rack_response[0],
      rack_response[1],
      JSON.parse(rack_response[2].first)
    )
  end
end
