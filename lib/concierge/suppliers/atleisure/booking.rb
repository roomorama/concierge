module AtLeisure

  # +AtLeisure::Booking+
  #
  # This class is responsible for wrapping the logic related to making a reservation
  # to AtLeisure, parsing the response, and building the +Reservation+ object with the data
  # returned from their API.
  #
  # Usage
  #
  #   result = AtLeisure::Booking.new(credentials).book(reservation_params)
  #   if result.success?
  #     process_reservation(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # The +book+ method returns a +Result+ object that, when successful, encapsulates the
  # resulting +Reservation+ object.
  #
  # Possible errors at this stage are:
  #
  # * +unrecognised_response+: happens when the request was successful, but the format
  #                            of the response is not compatible to this class' expectations.
  class Booking
    ENDPOINT                  = "https://placebookingv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm"
    DEFAULT_COUNTRY_CODE      = "SG"
    DEFAULT_CUSTOMER_LANGUAGE = "EN"

    # set default email to prevent emails to guest with confusing information
    DEFAULT_USER_EMAIL        = "atleisure@roomorama.com"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Calls the PlaceBookingV1 method from the AtLeisure JSON-RPC interface.
    # Returns a +Result+ object.
    def book(params)
      client = jsonrpc(ENDPOINT)
      result = client.invoke("PlaceBookingV1", reservation_details(params))

      if result.success?
        parse_book_response(params, result.value)
      else
        result
      end
    end

    private

    def parse_book_response(params, response)
      reservation = build_reservation(params)

      if response["BookingNumber"].blank?
        no_booking_information
        unrecognised_response
      else
        reservation.reference_number = response["BookingNumber"]
        Result.new(reservation)
      end
    end

    def build_reservation(params)
      Reservation.new(params)
    end

    def unrecognised_response
      Result.error(:unrecognised_response)
    end

    def jsonrpc(endpoint)
      Concierge::JSONRPC.new(endpoint)
    end

    def no_booking_information
      message = "No booking information could be retrieved. Expected field `BookingNumber`"

      mismatch(message, caller)
    end

    def mismatch(message, backtrace)
      response_mismatch = Concierge::Context::ResponseMismatch.new(
        message:   message,
        backtrace: backtrace
      )

      Concierge.context.augment(response_mismatch)
    end

    def reservation_details(params)
      {
        "HouseCode"                => params[:property_id],
        "ArrivalDate"              => params[:check_in].to_s,
        "DepartureDate"            => params[:check_out].to_s,
        "NumberOfAdults"           => params[:guests],
        "WebsiteRentPrice"         => params[:subtotal],
        "CustomerSurname"          => params[:customer][:last_name],
        "CustomerInitials"         => params[:customer][:first_name],
        "CustomerEmail"            => DEFAULT_USER_EMAIL,
        "CustomerTelephone1Number" => params[:customer][:phone],
        "BookingOrOption"          => "Booking",
        "CustomerCountry"          => DEFAULT_COUNTRY_CODE,
        "CustomerLanguage"         => DEFAULT_CUSTOMER_LANGUAGE,
        "NumberOfChildren"         => 0,
        "NumberOfBabies"           => 0,
        "NumberOfPets"             => 0,
        "Test"                     => credentials.test_mode
      }.merge!(authentication_params)
    end

    def authentication_params
      @authentication_params ||= {
        "WebpartnerCode"     => credentials.username,
        "WebpartnerPassword" => credentials.password
      }
    end

  end

end
