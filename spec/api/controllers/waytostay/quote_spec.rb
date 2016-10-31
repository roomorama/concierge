require "spec_helper"
require "concierge/result"
require_relative "../shared/quote_validations"
require_relative "../shared/quote_call"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::Waytostay::Quote do
  include Support::HTTPStubbing
  include Support::Factories
  include Concierge::Errors::Quote

  let(:supplier) { create_supplier(name: Waytostay::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id, fee_percentage: 7) }
  let(:property) { create_property(identifier: "567", host_id: host.id) }
  let(:params) {
    { property_id: property.identifier, check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
  }

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like "external error reporting" do
    let(:params) {
      { property_id: property.identifier, unit_id: "123", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
    }
    let(:supplier_name) { "WayToStay" }
    let(:error_code) { "savon_erorr" }

    def provoke_failure!
      # Timesout with trying to get token
      allow_any_instance_of(OAuth2::Client).to receive(:get_token) { raise Faraday::TimeoutError }
      Struct.new(:code).new("connection_timeout")
    end
  end

  it_behaves_like "quote call"

end
