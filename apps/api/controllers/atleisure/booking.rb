require_relative "../booking"

module API::Controllers::AtLeisure

  # API::Controllers::AtLeisure::Booking
  #
  # Performs create booking for properties from AtLeisure.
  class Booking
    include API::Controllers::Booking

    def create_booking(params)
      credentials = Concierge::Credentials.for(supplier_name)
      AtLeisure::Client.new(credentials).book(params)
    end

    def supplier_name
      AtLeisure::Client::SUPPLIER_NAME
    end
  end
end
