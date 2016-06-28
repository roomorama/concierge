require_relative "../booking"

module API::Controllers::SAW

  # +API::Controllers::AtLeisure::Booking+
  #
  # Performs create booking for properties from SAW.
  class Booking
    include API::Controllers::Booking

    params API::Controllers::Params::MultiUnitBooking

    # Make property booking request 
    #
    # Usage
    #
    #   It returns a +Reservation+ object in both success and fail cases:
    #   
    #   API::Controllers::SAW::Booking.create_booking(selected_params)
    #   => Reservation(..)
    def create_booking(params)
      credentials = Concierge::Credentials.for("SAW")
      SAW::Client.new(credentials).book(params)
    end
  end
end
