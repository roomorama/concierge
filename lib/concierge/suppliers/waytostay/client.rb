require_relative 'quote'
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

    include Waytostay::Quote

    attr_reader :credentials

    # credentails should include client_id and client_secret
    def initialize
      @credentials = Concierge::Credentials.for("waytostay")
    end

    def oauth2_client
      @oauth2_client ||= API::Support::OAuth2Client.new(id:        credentials.client_id,
                                                        secret:    credentials.client_secret,
                                                        base_url:  credentials.url,
                                                        token_url: credentials.token_url)
    end

    private

    def headers
      {
        "Content-Type"=>"application/json",
        "Accept"=>"application/json"
      }
    end

    def contains_all?(required_fields, response)
      required_fields.all? { |key|
        if response.get(key).nil?
          announce_missing_field(key)
          false
        else
          true
        end
      }
    end

    def announce_missing_field(f)
      event = Concierge::Context::ResponseMismatch.new(
        message:   "Response does not contain mandatory field `#{f}`.",
        backtrace: caller
      )
      Concierge.context.augment(event)
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
