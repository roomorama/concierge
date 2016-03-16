require_relative "../booking"
require_relative "../params/multi_unit_booking"

module API::Controllers::JTB

  # API::Controllers::JTB::Booking
  #
  # Performs create booking for properties from JTB.
  class Booking
    include API::Controllers::Booking

    params API::Controllers::Params::MultiUnitBooking

    def create_booking(params)
      credentials = Concierge::Credentials.for("jtb")
      JTB::Client.new(credentials).book(params)
    end

  end
end
