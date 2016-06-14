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
      post_body = {
        property_reference: params.fetch(:property_id),
        arrival_date: params.fetch(:check_in),
        departure_date: params.fetch(:check_out),
        number_of_adults: params.fetch(:guests)
      }
      result = oauth2_client.post(ENDPOINTS[:quote],
                                 body: post_body.to_json,
                                 headers: headers)

      if result.success?
        Quotation.new(quote_params_from(result.value))
      else
        announce_error("quote", result)
        Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
      end
    end

    def oauth2_client
      @oauth2_client ||= API::Support::OAuth2Client.new(id: credentials.client_id,
                                                        secret: credentials.client_secret,
                                                        base_url: credentials.url,
                                                        token_url: credentials.token_url)
    end

    private

    def quote_params_from json
      details = json["booking_details"]
      {
        property_id: details["property_reference"],
        check_in: details["arrival_date"],
        check_out: details["departure_date"],
        guests: details["number_of_adults"], #should we add infants?
        fee: details["price"]["pricing_summary"]["agency"]["commission_amount"],
        total: details["price"]["pricing_summary"]["final_price"],
        currency: details["price"]["currency"],
        available: true,
      }
    end

    def headers
      {
        "Content-Type"=>"application/json",
        "Accept"=>"application/json"
      }
    end

    def announce_error(operation, result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   operation,
        supplier:    SUPPLIER_NAME,
        code:        result.error.code,
        message:     "DEPRECATED",
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

  end
end
