require_relative "../booking"

module API::Controllers::Kigo::Legacy

  # API::Controllers::Kigo::Legacy::Booking
  #
  # Performs create booking for properties from Kigo::Legacy.
  class Booking
    include API::Controllers::Booking

    def create_booking(params)
      credentials = Concierge::Credentials.for("KigoLegacy")
      Kigo::Legacy.new(credentials).book(params)
    end

  end
end
