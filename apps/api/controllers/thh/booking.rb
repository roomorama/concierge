require_relative "../booking"

module API::Controllers::THH

  # +API::Controllers::THH::Booking+
  #
  # Performs create booking for properties from THH.
  class Booking
    include API::Controllers::Booking

    def create_booking(params)
      credentials = Concierge::Credentials.for(supplier_name)
      THH::Client.new(credentials).book(params)
    end

    def supplier_name
      THH::Client::SUPPLIER_NAME
    end
  end
end