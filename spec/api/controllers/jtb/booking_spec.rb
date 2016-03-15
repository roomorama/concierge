require 'spec_helper'
require_relative "../shared/booking_validations"


RSpec.describe API::Controllers::JTB::Booking do

  it_behaves_like "performing booking parameters validations", controller_generator: -> { described_class.new }

end
