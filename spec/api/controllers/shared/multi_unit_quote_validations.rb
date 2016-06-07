require "spec_helper"
require_relative "../shared/quote_validations"

RSpec.shared_examples "performing multi unit parameter validations" do |controller_generator:|

  let(:params) {
    { property_id: "A123", check_in: "2016-03-22", check_out: "2016-03-24", guests: 2, unit_id: "EX333" }
  }

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it "is invalid without a unit_id" do
    params.delete(:unit_id)
    response = call(controller_generator.call, params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["unit_id"]).to eq ["unit_id is required"]
  end

  private

  def call(controller, params)
    response = controller.call(params)

    # Wrap Rack data structure for an HTTP response
    Support::ResponseWrapper.new(
        response[0],
        response[1],
        JSON.parse(response[2].first)
    )
  end
end
