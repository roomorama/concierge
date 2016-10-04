require "spec_helper"
require_relative "../shared/multi_unit_quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::JTB::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::Factories

  let!(:supplier) { create_supplier(name: JTB::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }
  let(:property) { create_property(identifier: "J123", host_id: host.id) }

  it_behaves_like "performing multi unit parameter validations", controller_generator: -> { described_class.new }

  it_behaves_like "external error reporting" do
    let(:params) {
      { property_id: property.identifier, unit_id: "123", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
    }
    let(:supplier_name) { "JTB" }
    let(:error_code) { "savon_erorr" }

    def provoke_failure!
      allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
      Struct.new(:code).new("savon_error")
    end
  end

  describe "#call" do
    let(:params) {
      { property_id: property.identifier, unit_id: "123J", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
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

    context "when stay length is > 15 days" do
      let(:params) {
        { property_id: property.identifier, unit_id: "123J", check_in: "2016-02-22", check_out: "2016-03-25", guests: 2 }
      }
      it "respond with the stay_too_long error" do
        response = parse_response(subject.call(params))
        expect(response.status).to eq 503
        expect(response.body["errors"]).to eq({"quote"=>"Maximum length of stay must be less than 15 nights."})
      end
    end

  end

  private

  def stub_quote(fixture:)
    allow_any_instance_of(JTB::Price).to receive(:remote_call) { Result.new(JSON.parse(read_fixture(fixture))) }
  end

end
