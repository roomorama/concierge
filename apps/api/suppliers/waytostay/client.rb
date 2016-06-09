module Waytostay
  # +Waytostay::Client+
  #
  # This class is a convenience class for interacting with Waytostay.
  # OAuth2 is used as authentication.
  #
  # Usage
  #
  #   quotation = Waytostay::Client.new(credentials).quote(stay_params)
  #   if quotation.sucessful?
  #     # ...
  #   end
  #
  # For more information on how to interact with Waytostay, check the project Wiki.
  class Client
    SUPPLIER_NAME = "Waytostay"
    ENDPOINTS = {
      quote: "/bookings/quote",
    }

    attr_reader :credentials

    # credentails should include client_id and client_secret
    def initialize
      @credentials = Concierge::Credentials.for("waytostay")
    end

    # Always returns a +Quotation+.
    # If an error happens in any step in the process of getting a response back from
    # Waytostay, a generic error message is sent back to the caller, and the failure
    # is logged.
    def quote(params)
      #return unavailable_quotation if params.stay_length > MAXIMUM_STAY_LENGTH
      result = oauth2_client.post(ENDPOINTS[:quote])

      if result.success?
        result.value["property_id"] = params[:property_id]
        Quotation.new(quote_params_from(result.value))
      else
        announce_error("quote", result)
        Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
      end
    end

    def quote_params_from json
        details = json["booking_details"]
        {
          property_id: json["property_id"],
          check_in: details["arrival_date"],
          check_out: details["departure_date"],
          guests: details["number_of_adults"], #should we add infants?
          fee: details["price"]["pricing_summary"]["agency"]["commission_amount"],
          total: details["price"]["pricing_summary"]["final_price"],
          currency: details["price"]["currency"],
          available: true,
        }
    end

    # Always returns a +Reservation+.
    # If an error happens in any step in the process of getting a response back from
    # JTB, a generic error message is sent back to the caller, and the failure
    # is logged.
    def book(params)
      result = JTB::Booking.new(credentials).book(params)
      if result.success?
        reservation = Reservation.new(params)
        reservation.code = result.value

        # workaround to keep booking code for reservation. Returns reservation
        database.create(reservation)
      else
        announce_error("booking", result)
        Reservation.new(errors: { booking: 'Could not book property with remote supplier' })
      end
    end

    def oauth2_client
      @oauth2_client ||= API::Support::OAuth2Client.new(id: credentials[:client_id],
                                                        secret: credentials[:client_secret],
                                                        base_url: credentials[:url],
                                                        token_url: credentials[:token_url])
    end


    private

    def announce_error(operation, result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   operation,
        supplier:    SUPPLIER_NAME,
        code:        result.error.code,
        message:     "DEPRECATED",
        context:     API.context.to_h,
        happened_at: Time.now
      })
    end

    def database
      @database ||= Concierge::OptionalDatabaseAccess.new(ReservationRepository)
    end

    def unavailable_quotation
      Quotation.new(errors: { quote: "Maximum length of stay must be less than #{MAXIMUM_STAY_LENGTH} nights." })
    end

  end
end
