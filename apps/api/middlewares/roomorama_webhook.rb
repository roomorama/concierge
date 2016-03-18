require_relative "../../../lib/concierge/json"
require_relative "../../../lib/concierge/safe_access_hash"

module API
  module Middlewares

    # +API::Middlewares::RoomoramaWebhook+
    #
    # This middleware is responsible for making Concierge compliant with the
    # request/response format expected by Roomorama. Without it, Concierge
    # has a cleaner, more concise request and response formats. However,
    # at the present moment Roomorama requires a specific format for the webhooks
    # to work, and this middleware makes Concierge compatible with it without
    # having to change Concierge's defaults.
    #
    # The way that is accomplished is by validating incoming webhooks and transforming
    # them to Concierge's format. After Concierge is done processing, this middleware
    # will expand Concierge's response back to the format expected by the webhooks.
    #
    # In the future, when the format of Roomorama webhooks gets simpler, this
    # middlware could be entirely removed.
    class RoomoramaWebhook

      # +API::Middlewares::RoomoramaWebhook::ConciergeRequest+
      #
      # This class is responsible for translating a webhook incoming request
      # to the format expected by Concierge.
      #
      # Example
      #
      #   request = ConciergeRequest.new(env)
      #   payload = {
      #     "event" => "quote_instant",
      #     # ...
      #     "room" => {
      #       "id" => 23304,
      #       "internal_id" => "023",
      #       "url" => "..."
      #     },
      #     "user" => {
      #       # ...
      #     }
      #   }
      #   request.quote(paylaod)
      #   # => Changes the request body to:
      #   # {
      #   #   property_id: "023",
      #   #   check_in: "...",
      #   #   check_out: "...",
      #   #   guests: 2
      #   # }
      class ConciergeRequest
        include Concierge::JSON

        attr_reader :env, :payload

        def initialize(env)
          @env = env
        end

        # translates params for a +quote+ call. Receives a +data+ argument
        # representing the webhook payload sent by Roomorama and changes
        # the request body to contain the format expected by Concierge.
        def quote(data)
          payload = safe_access(data)

          params = {
            property_id: payload.get("inquiry.room.internal_id"),
            unit_id:     payload.get("inquiry.room.unit_id"),
            check_in:    payload.get("inquiry.check_in"),
            check_out:   payload.get("inquiry.check_out"),
            guests:      payload.get("inquiry.num_guests")
          }

          env["rack.input"] = StringIO.new(json_encode(params))
          true
        end

        # translates params for a +booking+ call. Receives a +data+ argument
        # representing the webhook payload sent by Roomorama and changes
        # the request body to contain the format expected by Concierge.
        def booking(data)
          payload = safe_access(data)

          params = {
            property_id: payload.get("inquiry.room.internal_id"),
            unit_id:     payload.get("inquiry.room.unit_id"),
            check_in:    payload.get("inquiry.check_in"),
            check_out:   payload.get("inquiry.check_out"),
            guests:      payload.get("inquiry.num_guests"),
            customer: {
              first_name: payload.get("inquiry.user.first_name"),
              last_name:  payload.get("inquiry.user.last_name"),
              email:      payload.get("inquiry.user.email"),
              phone:      payload.get("inquiry.user.phone_number")
            }
          }

          env["rack.input"] = StringIO.new(json_encode(params))
          true
        end

        def request_path
          env["PATH_INFO"] || env["REQUEST_PATH"]
        end

        private

        def safe_access(hash)
          Concierge::SafeAccessHash.new(hash)
        end
      end

      # +API::Middlewares::RoomoramaWebhook::WebhookResponse+
      #
      # This class is responsible for translating Concierge's response format
      # back to the format expected by Roomorama's webhooks.
      #
      # Example
      #
      #   payload = {
      #     "event" => "quote_instant",
      #     # ...
      #     "room" => {
      #       "id" => 23304,
      #       "internal_id" => "023",
      #       "url" => "..."
      #     },
      #     "user" => {
      #       # ...
      #     }
      #   }
      #   response = WebhookResponse.new(payload)
      #   headers = { ... }
      #   response.quote(200, headers, response)
      #   # => [422, headers, "..."]
      class WebhookResponse
        include Concierge::JSON

        attr_reader :payload

        # Receives a +payload+ that represents the webhook paylaod initially sent
        # for this request/response cycle. Necessary since the response is basically
        # the same payload, with booking quotation values modified.
        def initialize(payload)
          @payload = payload
        end

        # Returns a response that is compatible with that expected by Roomorama.
        # When the property is unavailable, Concierge indicates so by having an
        # +available+ field set to +false+. However, to make it compatible with
        # webhooks, we need to change the HTTP status to a non-successful one in
        # that scenario. This also changes the response status to +422+ in case any
        # other error happened during the process.
        #
        # On success, it changes the price fields of the initial webhook payload
        # to include those quoted by Concierge.
        def quote(status, headers, response)
          available = (response["status"] == "ok" && response["available"] == true)
          return [422, headers, [json_encode(response)]] unless available

          payload["inquiry"].merge!({
            "base_rental"            => response["total"],
            "currency_code"          => response["currency"],
            "tax"                    => 0,
            "processing_fee"         => 0,
            "extra_guests_surcharge" => 0,
            "subtotal"               => response["total"],
            "total"                  => response["total"]
          })

          [status, headers, [json_encode(payload)]]
        end

        # When making a booking, Roomorama checks only the HTTP status code of
        # the response, and not the content itself. In that sense, it is enough
        # to use the status code and response from Concierge, since they should
        # indicate whether or not the booking was successful.
        def booking(status, headers, response)
          [status, headers, [json_encode(response)]]
        end
      end

      include Concierge::JSON

      attr_reader :app, :env, :webhook_payload

      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env

        if webhook_to_concierge
          response = app.call(env)
          concierge_to_webhook(response)
        else
          [422, {}, ["Invalid webhook"]]
        end
      end

      private

      # tries to convert an incoming webhook to a valid Concierge
      # request. Fails if:
      #
      # * the request body is not valid JSON.
      # * there is no +event+ field.
      # * the content of the +event+ field is not recognized.
      def webhook_to_concierge
        request_body = read_request_body(env)
        json_payload = json_decode(request_body)
        return false unless json_payload.success?

        @webhook_payload = json_payload.value
        event            = webhook_payload["event"]

        case event
        when "price_check", "quote_instant"
          concierge_request.quote(webhook_payload)
        when "booked_instant"
          concierge_request.booking(webhook_payload)
        else
          # event is not recognized and should not be handled.
          false
        end
      end

      def concierge_to_webhook(response)
        status, headers, body = response
        json_response         = json_decode(body.first)

        # this is not a valid Rack response, but the response here is a valid
        # JSON since it came from Concierge.
        return false unless json_response.success?

        data  = json_response.value
        event = webhook_payload["event"]

        case event
        when "price_check", "quote_instant"
          webhook_response.quote(status, headers, data)
        when "booked_instant"
          webhook_response.booking(status, headers, data)
        end
      end

      def request_path
        env["PATH_INFO"] || env["REQUEST_PATH"]
      end

      def concierge_request
        ConciergeRequest.new(env)
      end

      def webhook_response
        WebhookResponse.new(webhook_payload)
      end

      def read_request_body(env)
        env["rack.input"].read.tap do
          env["rack.input"].rewind
        end
      end

    end
  end

end
