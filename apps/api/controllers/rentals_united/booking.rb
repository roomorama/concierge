require_relative "../booking"
require_relative "../params/booking"

module API::Controllers::RentalsUnited

  # +API::Controllers::RentalsUnited::Booking+
  #
  # Performs create booking for properties from RentalsUnited.
  class Booking
    include API::Controllers::Booking

    params API::Controllers::Params::Booking

    # Make property booking request
    #
    # Usage
    #
    #   It returns a +Reservation+ object in both success and fail cases:
    #
    #   API::Controllers::RentalsUnited::Booking.create_booking(selected_params)
    #   => Reservation(..)
    def create_booking(params)
      credentials = Concierge::Credentials.for(supplier_name)
      RentalsUnited::Client.new(credentials).book(params)
    end

    def supplier_name
      RentalsUnited::Client::SUPPLIER_NAME
    end
  end
end
