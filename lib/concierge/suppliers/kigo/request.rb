module Kigo

  # +Kigo::Request+
  #
  # This class is responsible for building the request payload to be sent to Kigo's
  # API, for different calls. It can be extended for usage with the Legacy API
  # due to the similarity of both interfaces.
  #
  # Usage
  #
  #   request = Kigo::Request.new(credentials)
  #   request.build_compute_pricing(params)
  #   # => #<Result error=nil value={ "PROP_ID" => 123, ... }>
  class Request
    BASE_URI = "https://www.kigoapis.com"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Returns a String with the base URL of the API.
    def base_uri
      BASE_URI
    end

    # Returns an authenticated HTTP client to be used with Kigo's API.
    # For Kigo's new API, authentication happens by appending a parameter
    # to the URL, so this just returns a regular +Concierge::HTTPClient+ instance.
    def http_client
      @http_client ||= Concierge::HTTPClient.new(base_uri, timeout: 40)
    end

    # builds the URL path to be used to perform a given +api_method+. For Kigo's new
    # API, credentials are appended to every API call by adding a +subscription-key+
    # parameter to the URL.
    def endpoint_for(api_method)
      ["/channels/v1/", api_method, "?subscription-key=", credentials.subscription_key].join
    end

    # Builds the required request parameters for a +computePricing+ Kigo API call.
    # Property identifiers are numerical in Kigo, and they must be sent as numbers.
    # Sending identifiers as strings produces an error.
    #
    # Returns a +Result+ instance encapsulating the operation. Fails with code
    # +invalid_property_id+ if the ID cannot be converted to an integer.
    def build_compute_pricing(params)
      property_id_conversion = to_integer(params[:property_id], :invalid_property_id)

      if property_id_conversion.success?
        Result.new({
          "PROP_ID"        => property_id_conversion.value,
          "RES_CHECK_IN"   => params[:check_in],
          "RES_CHECK_OUT"  => params[:check_out],
          "RES_N_ADULTS"   => params[:guests].to_i,
          "RES_N_CHILDREN" => 0
        })
      else
        property_id_conversion
      end
    end

    # Builds the required request parameters for a +createConfirmedReservation+ Kigo API call.
    # Property identifiers are numerical in Kigo, and they must be sent as numbers.
    # Sending identifiers as strings produces an error.
    #
    # Returns a +Result+ instance encapsulating the operation. Fails with code
    # +invalid_property_id+ if the ID cannot be converted to an integer.
    def build_reservation_details(params)
      property_id_conversion = to_integer(params[:property_id], :invalid_property_id)

      if property_id_conversion.success?
        details = {
          "PROP_ID"        => property_id_conversion.value,
          "RES_CHECK_IN"   => params[:check_in],
          "RES_CHECK_OUT"  => params[:check_out],
          "RES_N_ADULTS"   => params[:guests],
          "RES_N_CHILDREN" => 0,
          "RES_COMMENT"    => "Booking made via Roomorama on #{Date.today}",
          "RES_GUEST"      => guest_details(params[:customer])
        }

        Result.new(details)
      else
        property_id_conversion
      end
    end

    private

    def guest_details(customer)
      {
        "RES_GUEST_EMAIL"     => customer[:email],
        "RES_GUEST_PHONE"     => customer[:phone].to_s,
        "RES_GUEST_COUNTRY"   => customer[:country],
        "RES_GUEST_LASTNAME"  => customer[:last_name],
        "RES_GUEST_FIRSTNAME" => customer[:first_name]
      }
    end

    def to_integer(str, error_code)
      Result.new(Integer(str))
    rescue ArgumentError => err
      non_numerical_property_id(str)
      Result.error(error_code)
    end

    def non_numerical_property_id(id)
      label   = "Invalid Kigo Property ID"
      message = "Expected a numerical Kigo property ID, but received instead `#{id}`."

      report_message(label, message, caller)
    end

    def report_message(label, message, backtrace)
      generic_message = Concierge::Context::Message.new(
        label:     label,
        message:   message,
        backtrace: backtrace
      )

      Concierge.context.augment(generic_message)
    end

  end

end
