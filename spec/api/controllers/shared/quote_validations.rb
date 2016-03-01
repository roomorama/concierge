require "spec_helper"

RSpec.shared_examples "performing parameter validations" do |controller_generator:|
  QuoteResponse = Struct.new(:status, :headers, :body)

  let(:valid_params) {
    { property_id: "A123", check_in: "2016-03-22", check_out: "2016-03-24", guests: 2 }
  }

  it "is invalid without a property_id" do
    valid_params.delete(:property_id)
    response = call(controller_generator, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["property_id"]).to eq ["property_id is required"]
  end

  it "is invalid without a check-in date" do
    valid_params.delete(:check_in)
    response = call(controller_generator, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_in"]).to eq ["check_in is required"]
  end

  it "is invalid without a check-out date" do
    valid_params.delete(:check_out)
    response = call(controller_generator, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_out"]).to eq ["check_out is required"]
  end

  it "is invalid without a number of guests" do
    valid_params.delete(:guests)
    response = call(controller_generator, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["guests"]).to eq ["guests is required"]
  end

  it "is invalid if the check-in format is not correct" do
    valid_params[:check_in] = "invalid-format"
    response = call(controller_generator, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_in"]).to eq ["check_in: invalid format"]
  end

  it "is invalid if the check-out format is not correct" do
    valid_params[:check_out] = "invalid-format"
    response = call(controller_generator, valid_params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_out"]).to eq ["check_out: invalid format"]
  end

  it "is valid if all parameters are correct" do
    response = call(controller_generator, valid_params)
    expect(response.status).to eq 200
    expect(response.body["status"]).to eq "ok"
  end


  private

  def call(generator, params)
    controller = generator.call
    response = controller.call(params)

    # Wrap Rack data structure for an HTTP response
    QuoteResponse.new(
      response[0],
      response[1],
      JSON.parse(response[2].first)
    )
  end
end
