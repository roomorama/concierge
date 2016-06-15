require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::Waytostay::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures

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

end
