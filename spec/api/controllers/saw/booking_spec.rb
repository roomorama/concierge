require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::SAW::Booking do
  include Support::HTTPStubbing
  include Support::Fixtures
  
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

  it "returns result object if booking request is completed successfully" do
    mock_request(:propertybooking, :success)
    
    result = controller.create_booking(request_params)
    
    expect(result.successful?).to be true
    expect(result).to be_kind_of(Reservation)
    expect(result.property_id).to eq(request_params[:property_id])
    expect(result.unit_id).to eq(request_params[:unit_id])
    expect(result.check_in).to eq(request_params[:check_in])
    expect(result.check_out).to eq(request_params[:check_out])
    expect(result.code).to eq('MTA66395')
  end

  it "returns an error if booking request fails" do
    mock_request(:propertybooking, :error)
    
    result = controller.create_booking(request_params)
  
    expect(result.successful?).to be false
    expect(result.errors[action]).to eq(
      "Could not create booking with remote supplier"
    )
  end

  private
  def mock_request(endpoint, filename)
    stub_data = read_fixture("saw/#{endpoint}/#{filename}.xml")
    stub_call(:post, endpoint_for(endpoint)) { [200, {}, stub_data] }
  end

  def endpoint_for(method)
    "http://staging.servicedapartmentsworldwide.net/xml/#{method}.aspx"
  end
end
