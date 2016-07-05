require "spec_helper"
require_relative "../shared/booking_validations"

RSpec.describe API::Controllers::SAW::Booking do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest
  
  let(:params) do
    {
      property_id: '1',
      unit_id: '9733',
      check_in: '02/02/2016',
      check_out: '03/02/2016',
      guests: 1,
      currency_code: 'EUR',
      subtotal: '123.45',
      customer: {
        first_name: 'Test',
        last_name: 'User',
        email: 'testuser@example.com',
        display: 'Test User'
      }
    }
  end

  let(:safe_params) { Concierge::SafeAccessHash.new(params) }
  let(:controller) { described_class.new }
  let(:action) { :booking }
  
  it_behaves_like "performing booking parameters validations", controller_generator: -> { described_class.new }

  it "returns result object with reservation if booking request is completed successfully" do
    mock_request(:propertybooking, :success)
    
    result = controller.create_booking(safe_params)
    
    expect(result.success?).to be true
    expect(result).to be_kind_of(Result)

    reservation = result.value
    expect(reservation).to be_kind_of(Reservation)
    expect(reservation.property_id).to eq(safe_params[:property_id])
    expect(reservation.unit_id).to eq(safe_params[:unit_id])
    expect(reservation.check_in).to eq(safe_params[:check_in])
    expect(reservation.check_out).to eq(safe_params[:check_out])
    expect(reservation.code).to eq('MTA66395')
  end

  it "returns an error reservation if booking request fails" do
    mock_request(:propertybooking, :error)
    
    result = controller.create_booking(safe_params)
    
    expect(result.success?).to be false
    expect(result).to be_kind_of(Result)
    expect(result.value).to be nil
  end
  
  context "when response from the SAW api is not well-formed xml" do
    it "returns a reservation with an appropriate error" do
      mock_bad_xml_request(:propertybooking)

      result = controller.create_booking(safe_params)
      
      expect(result.success?).to be false
      expect(result).to be_kind_of(Result)
      expect(result.value).to be nil
    end
  end
end
