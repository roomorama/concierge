require "spec_helper"
require_relative "../shared/multi_unit_quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::JTB::Quote do

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

end
