require "spec_helper"

RSpec.shared_examples "performing pull-calendar parameter validations" do |controller_generator:|

  it "is invalid without a property_id" do
    valid_params.delete(:property_id)
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["property_id"]).to eq ["property_id is required"]
  end

  it "is invalid without a from_date" do
    valid_params.delete(:from_date)
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["from_date"]).to eq ["from_date is required"]
  end

  it "is invalid without a to_date" do
    valid_params.delete(:to_date)
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["to_date"]).to eq ["to_date is required"]
  end

  it "is invalid if the to_date date is not after the from_date" do
    valid_params[:to_date] = (Date.parse(valid_params[:from_date]) - 1).to_s
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["to_date"]).to eq ["to_date needs to be after from_date"]
  end

  it "is invalid if the from_date format is not correct" do
    valid_params[:from_date] = "invalid-format"
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["from_date"]).to eq ["from_date: invalid format"]
  end

  it "is invalid if the to_date format is not correct" do
    valid_params[:to_date] = "invalid-format"
    response = call(controller_generator.call, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["to_date"]).to eq ["to_date: invalid format"]
  end

  it "is valid if all parameters are correct" do
    controller = controller_generator.call
    allow(controller).to receive(:pull_calendar) { Calendar.new(errors: []) }

    response = call(controller, valid_params)
    expect(response.status).to eq 200
    expect(response.body["status"]).to eq "ok"
  end

  it "fails if the price quotation is not successful" do
    controller = controller_generator.call
    allow(controller).to receive(:pull_calendar) { Calendar.new(errors: { failure: "Supplier unavailable" }) }

    response = call(controller, valid_params)
    expect(response.status).to eq 503
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]).to eq({ "failure" => "Partner unavailable" })
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
