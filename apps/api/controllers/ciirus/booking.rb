require_relative "../booking"

module API::Controllers::Ciirus

  # +API::Controllers::Ciirus::Booking+
  #
  # Performs create booking for properties from Ciirus.
  class Booking
    include API::Controllers::Booking

    def create_booking(params)
      credentials = Concierge::Credentials.for("Ciirus")
      Ciirus::Client.new(credentials).book(params)
    end

    def supplier_name
      Ciirus::Client::SUPPLIER_NAME
    end
  end
end
