require_relative "../booking"

module API::Controllers::Kigo

  # API::Controllers::Kigo::Booking
  #
  # Performs create booking for properties from Kigo.
  class Booking
    include API::Controllers::Booking

    def create_booking(params)
      credentials = Concierge::Credentials.for("Kigo")
      Kigo::Client.new(credentials).book(params)
    end

    def supplier_name
      Kigo::Client::SUPPLIER_NAME
    end

  end
end
