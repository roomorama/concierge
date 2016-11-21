require "spec_helper"

RSpec.shared_examples "booking call" do
  include Concierge::Errors::Booking
  subject { described_class.new.call(params) }

  context "client returns network_error" do
    it "returns a generic error message" do
      expect_any_instance_of(described_class).to receive(:create_booking).and_return(Result.error(:network_error))
      response = parse_response(subject)
      expect(response.status).to eq 503
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["booking"]).to eq "Could not create booking with remote supplier"
    end
  end

  context "client returns not available" do
    it "returns proper error messages if client returns not available" do
      expect_any_instance_of(described_class).to receive(:create_booking).and_return(not_available)
      response = parse_response(subject)
      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["booking"]).to eq "Property not available for booking"
    end
  end

  it "returns reservation when call is successful" do
    reservation = Reservation.new({
        property_id:      params[:property_id],
        check_in:         params[:check_in],
        check_out:        params[:check_out],
        guests:           params[:guests],
        customer:         params[:customer],
        reference_number: '152345'
      })
    expect_any_instance_of(described_class).to receive(:create_booking).and_return(Result.new(reservation))

    response = parse_response(subject)
    expect(response.status).to eq 200
    expect(response.body["status"]).to eq "ok"
    expect(response.body["property_id"]).to eq params[:property_id]
    expect(response.body["check_in"]).to eq params[:check_in]
    expect(response.body["check_out"]).to eq params[:check_out]
    expect(response.body["guests"]).to eq params[:guests]
    expect(response.body["reference_number"]).to eq '152345'
    expect(response.body["customer"]).to eq params[:customer]
  end
end

