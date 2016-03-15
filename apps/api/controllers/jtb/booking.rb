require_relative "../booking"

module API::Controllers::JTB

  # API::Controllers::JTB::Booking
  #
  # Performs create booking for properties from JTB.
  class Booking
    include API::Controllers::Booking

    def create_booking(params)
      credentials = Credentials.for("jtb")
      JTB::Client.new(credentials).book(params)
    end

  end
end
