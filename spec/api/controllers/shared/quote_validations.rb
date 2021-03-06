require "spec_helper"

RSpec.shared_examples "performing parameter validations" do |controller_generator:|

  it "is invalid without a property_id" do
    valid_params.delete(:property_id)
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["property_id"]).to eq ["property_id is required"]
  end

  it "is invalid without a check-in date" do
    valid_params.delete(:check_in)
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_in"]).to eq ["check_in is required"]
  end

  it "is invalid without a check-out date" do
    valid_params.delete(:check_out)
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_out"]).to eq ["check_out is required"]
  end

  it "is invalid if the check-out date is not after the check-in date" do
    valid_params[:check_out] = (Date.parse(valid_params[:check_in]) - 1).to_s
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_out"]).to eq ["check_out needs to be after check-in"]
  end

  it "is invalid without a number of guests" do
    valid_params.delete(:guests)
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["guests"]).to eq ["guests is required"]
  end

  it "is invalid if the check-in format is not correct" do
    valid_params[:check_in] = "invalid-format"
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_in"]).to eq ["check_in: invalid format"]
  end

  it "is invalid if the check-out format is not correct" do
    valid_params[:check_out] = "invalid-format"
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_out"]).to eq ["check_out: invalid format"]
  end

  it "is valid if all parameters are correct" do
    controller = controller_generator.call
    allow(controller).to receive(:quote_price) { Result.new(Quotation.new(errors: [])) }

    response = call(controller, valid_params)
    expect(response.status).to eq 200
    expect(response.body["status"]).to eq "ok"
  end

  it "fails if the price quotation is not successful" do
    controller = controller_generator.call
    allow(controller).to receive(:quote_price) { Result.error(:network_failure) }

    response = call(controller, valid_params)
    expect(response.status).to eq 503
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]).to eq({ "quote"  => "Could not quote price with remote supplier" })
  end

  it "returns 404 if property is not found in the database" do
    controller = controller_generator.call
    allow(controller).to receive(:property_exists?) { false }

    response = call(controller, valid_params)
    expect(response.status).to eq 404
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]).to eq("Property not found")
  end

  private

  def call(controller, params)
    response = controller.call(params)

    # Wrap Rack data structure for an HTTP response
    Support::HTTPStubbing::ResponseWrapper.new(
      response[0],
      response[1],
      JSON.parse(response[2].first)
    )
  end
end
