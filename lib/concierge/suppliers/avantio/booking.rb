module Avantio

  # +Avantio::Booking+
  #
  # This class is responsible for wrapping the logic related to making a booking
  # to Avantio, parsing the response, and building the +Reservation+ object with the data
  # returned from their API.
  #
  # Usage
  #
  #   result = Avantio::Booking.new(credentials).book(stay_params)
  #   if result.success?
  #     process_reservation(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # The +quote+ method returns a +Result+ object that, when successful, encapsulates the
  # resulting +Reservation+ object.
  class Booking
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def book(params)
      # We should check availability at first, because
      # Avantio booking call can return valid reservation even for not available periods
      available = Avantio::Commands::IsAvailableFetcher.new(credentials).call(params)
      return available unless available.success?

      return Result.error(:unavailable_accommodation) unless available.value

      Avantio::Commands::SetBooking.new(credentials).call(params)
    end
  end
end