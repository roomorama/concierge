require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::SAW::Booking do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest
  
  let(:request_params) do
    {
      property_id: '1',
      unit_id: '9733',
      check_in: '02/02/2016',
      check_out: '03/02/2016',
      num_guests: 1,
      currency_code: 'EUR',
      total: '123.45',
      user: {
        firstname: 'Test',
        lastname: 'User',
        email: 'testuser@example.com',
        display: 'Test User'
      }
    }
  end

  let(:controller) { described_class.new }
  let(:action) { :booking }

  it "returns reservation object if booking request is completed successfully" do
    mock_request(:propertybooking, :success)
    
    reservation = controller.create_booking(request_params)
    
    expect(reservation.successful?).to be true
    expect(reservation).to be_kind_of(Reservation)
    expect(reservation.property_id).to eq(request_params[:property_id])
    expect(reservation.unit_id).to eq(request_params[:unit_id])
    expect(reservation.check_in).to eq(request_params[:check_in])
    expect(reservation.check_out).to eq(request_params[:check_out])
    expect(reservation.code).to eq('MTA66395')
  end

  it "returns an error reservation if booking request fails" do
    mock_request(:propertybooking, :error)
    
    reservation = controller.create_booking(request_params)
  
    expect(reservation.successful?).to be false
    expect(reservation.errors[action]).to eq(
      "Could not create booking with remote supplier"
    )
  end
  
  context "when response from the SAW api is not well-formed xml" do
    it "returns a reservation with an appropriate error" do
      mock_request(:propertybooking, :bad_xml)

      reservation = controller.create_booking(request_params)
      
      expect(reservation.successful?).to be false
      expect(reservation.errors[action]).to eq(
        "Could not create booking with remote supplier"
      )
    end
  end
end
