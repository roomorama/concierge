module Poplidays

  # +Poplidays::Booking+
  #
  # This class is responsible for wrapping the logic related to making a reservation
  # to Poplidays, parsing the response, and building the +Reservation+ object with the data
  # returned from their API.
  #
  # Usage
  #
  #   result = Poplidays::Booking.new(credentials).book(reservation_params)
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
      fetcher = Poplidays::Commands::Booking.new(credentials)
      raw_booking = fetcher.call(params)

      return raw_booking unless raw_booking.success?

      reservation = mapper.build(params, raw_booking.value)
      Result.new(reservation)
    end

    private

    def mapper
      @mapper ||= Poplidays::Mappers::RoomoramaReservation.new
    end
  end

end
