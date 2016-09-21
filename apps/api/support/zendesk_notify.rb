module API::Support

  # +API::Support::ZendeskNotify+
  #
  # This is a client class to the +ZendeskNotify+ service, a simple API to
  # send tickets on Roomorama/BridgeRentals Zendesk account.
  #
  # Usage
  #
  #   client = API::Support::ZendeskNotify.new
  #   ticket_id = "cancellation"
  #   attributes = {
  #     supplier:    "Supplier X",
  #     supplier_id: "212",
  #     bridge_id:   "291"
  #   }
  #
  #   client.notify # => <#Result value=true>
  #
  # The +attributes+ passed when calling the +notify+ method are dependent on the
  # type of ticket being sent.
  class ZendeskNotify
    include Concierge::JSON

    SUPPORTED_TICKETS = %w(cancellation)

    # Zendesk's API is very slow when sending tickets. Especially on the sandbox
    # environment. As the cancellation webhook is sent on the background, without
    # blocking the user interface, we can afford a higher timeout.
    CONNECTION_TIMEOUT = 20

    attr_reader :http, :endpoint

    # initializes internal state. The +ZendeskNotify+ service URL must be properly
    # configured on the +ZENDESK_NOTIFY_URL+ environment variable.
    def initialize
      uri  = URI.parse(zendesk_notify_url)
      host = [uri.scheme, "://", uri.host].join

      @http     = Concierge::HTTPClient.new(host, timeout: CONNECTION_TIMEOUT)
      @endpoint = uri.request_uri
    end

    def notify(ticket_id, attributes)
      return invalid_ticket unless SUPPORTED_TICKETS.include?(ticket_id.to_s)

      params = {
        ticketId:   ticket_id,
        attributes: attributes
      }

      result = http.post(endpoint, json_encode(params), { "Content-Type" => "application/json" })
      return result unless result.success?

      parse_response(result.value.body)
    end

    private

    # expected response (examples)
    #
    # Success
    #   { "status": "ok", "message": "Ticket sent successfully" }
    #
    # Failure
    #   { "status": "error", "message": "Failure to deliver ticket" }
    def parse_response(body)
      decoded_body = json_decode(body)
      return decoded_body unless decoded_body.success?

      successful = (decoded_body.value["status"] == "ok")

      if successful
        Result.new(true)
      else
        error_message = decoded_body.value["message"]
        Result.error(:zendesk_notify_failure, error_message)
      end
    end

    def invalid_ticket
      Result.error(:zendesk_invalid_ticket)
    end

    def zendesk_notify_url
      ENV["ZENDESK_NOTIFY_URL"]
    end

  end

end
