module THH

  # +THH::Booking+
  #
  # This class is responsible for wrapping the logic related to making a reservation
  # to THH, parsing the response, and building the +Reservation+ object with the data
  # returned from their API.
  #
  # Usage
  #
  #   result = THH::Booking.new(credentials).book(reservation_params)
  #   if result.success?
  #     process_reservation(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # The +book+ method returns a +Result+ object that, when successful, encapsulates the
  # resulting +Reservation+ object.

  class Booking
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Makes booking. Used booking/easy endpoint in "BOOKED" mode.
    def book(params)
      fetcher = THH::Commands::Booking.new(credentials)
      raw_booking = fetcher.call(params)

      return raw_booking unless raw_booking.success?

      reservation = build_reservation(params, raw_booking.value)
      Result.new(reservation)
    end

    private

    def build_reservation(params, response)
      Reservation.new(params).tap do |r|
        r.reference_number = response['booking_id']
      end
    end
  end
end
