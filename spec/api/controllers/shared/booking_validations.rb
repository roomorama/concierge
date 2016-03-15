require "spec_helper"

RSpec.shared_examples "performing booking parameters validations" do |controller_generator:|

  let(:params) {
    {
      property_id: "A123",
      check_in:    "2016-03-22",
      check_out:   "2016-03-24",
      guests:      2,
      customer:    {
        first_name:  "Alex",
        last_name:   "Black",
        country:     "India",
        city:        "Mumbai",
        address:     "first street",
        postal_code: "123123",
        email:       "test@example.com",
        phone:       "555-55-55",
      }
    }
  }

  it "is invalid without a property_id" do
    params.delete(:property_id)
    response = call(controller_generator.call, params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["property_id"]).to eq ["property_id is required"]
  end

  it "is invalid without a check-in date" do
    params.delete(:check_in)
    response = call(controller_generator.call, params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_in"]).to eq ["check_in is required"]
  end

  it "is invalid without a check-out date" do
    params.delete(:check_out)
    response = call(controller_generator.call, params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_out"]).to eq ["check_out is required"]
  end

  it "is invalid without a number of guests" do
    params.delete(:guests)
    response = call(controller_generator.call, params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["guests"]).to eq ["guests is required"]
  end

  it "is invalid if the check-in format is not correct" do
    params[:check_in] = "invalid-format"
    response          = call(controller_generator.call, params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_in"]).to eq ["check_in: invalid format"]
  end

  it "is invalid if the check-out format is not correct" do
    params[:check_out] = "invalid-format"
    response           = call(controller_generator.call, params)

    expect(response.status).to eq 422
    expect(response.body["status"]).to eq "error"
    expect(response.body["errors"]["check_out"]).to eq ["check_out: invalid format"]
  end

  context "customer" do
    %w(first_name last_name country city address postal_code phone).map do |attribute|
      it "is invalid without #{attribute}" do
        params[:customer].delete(attribute.to_sym)
        response = call(controller_generator.call, params)

        expect(response.status).to eq 422
        expect(response.body["status"]).to eq "error"
        expect(response.body["errors"]["customer.#{attribute}"]).to eq ["customer.#{attribute} is required"]
      end
    end
  end
  
  private

  Response = Struct.new(:status, :headers, :body)

  def call(controller, params)
    response = controller.call(params)
    # Wrap Rack data structure for an HTTP response
    Response.new(
      response[0],
      response[1],
      JSON.parse(response[2].first)
    )
  end
end
