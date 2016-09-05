require_relative "../booking"
require_relative "../params/multi_unit_booking"

module API::Controllers::Woori

  # +API::Controllers::Woori::Booking+
  #
  # Performs create booking for properties from Woori.
  class Booking
    include API::Controllers::Booking

    params API::Controllers::Params::MultiUnitBooking

    # Make property booking request
    #
    # Usage
    #
    #   API::Controllers::Woori::Booking.create_booking(selected_params)
    #   => Reservation(..)
    #
    # Returns a +Result+ wrapping a +Reservation+ when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def create_booking(params)
      credentials = Concierge::Credentials.for(supplier_name)
      Woori::Client.new(credentials).book(params)
    end

    def supplier_name
      Woori::Client::SUPPLIER_NAME
    end
  end
end
