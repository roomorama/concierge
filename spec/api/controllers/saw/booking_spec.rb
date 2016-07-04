require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::SAW::Booking do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest
  
  let(:request_attributes) do
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

  let(:request_params) { Concierge::SafeAccessHash.new(request_attributes) }
  let(:controller) { described_class.new }
  let(:action) { :booking }

  it "returns result object with reservation if booking request is completed successfully" do
    mock_request(:propertybooking, :success)
    
    result = controller.create_booking(request_params)
    
    expect(result.success?).to be true
    expect(result).to be_kind_of(Result)

    reservation = result.value
    expect(reservation).to be_kind_of(Reservation)
    expect(reservation.property_id).to eq(request_params[:property_id])
    expect(reservation.unit_id).to eq(request_params[:unit_id])
    expect(reservation.check_in).to eq(request_params[:check_in])
    expect(reservation.check_out).to eq(request_params[:check_out])
    expect(reservation.code).to eq('MTA66395')
  end

  it "returns an error reservation if booking request fails" do
    mock_request(:propertybooking, :error)
    
    result = controller.create_booking(request_params)
    
    expect(result.success?).to be false
    expect(result).to be_kind_of(Result)
    expect(result.value).to be nil
  end
  
  context "when response from the SAW api is not well-formed xml" do
    it "returns a reservation with an appropriate error" do
      mock_bad_xml_request(:propertybooking)

      result = controller.create_booking(request_params)
      
      expect(result.success?).to be false
      expect(result).to be_kind_of(Result)
      expect(result.value).to be nil
    end
  end
end
