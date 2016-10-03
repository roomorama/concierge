require_relative "../../../lib/concierge/json"
require_relative "../../../lib/concierge/safe_access_hash"

module API::Middlewares

  # +API::Middlewares::QuoteValidations+
  #
  # Quotation queries requires that Concierge knows what host_fee to
  # append to the response from supplier. Hence we require that the property
  # record, and hence the host record, exists on Concierge. If we don't impose
  # this check, a quote call to partner would succeed (for active property) and
  # Concierge would mistakenly return $0 for host fee to Roomorama.
  #
  # This should be called after RoomoramaWebhook, so we expect the massaged
  # concierge params
  class QuoteValidations

    include Concierge::JSON

    attr_reader :app, :env, :webhook_payload

    def initialize(app)
      @app = app
    end

    def call(env)
      @env = env

      return app.call(env) unless quote_request?

      return app.call(env) if property_exists?

      [404, {}, ["Property not found on Concierge"]]
    end

    private

    def quote_request?
      env['PATH_INFO'].include? 'quote'
    end

    def property_exists?
      body = read_request_body(env)
      json_payload = json_decode(body)
      property = PropertyRepository.identified_by(json_payload.value["property_id"])
      property.count > 0
    end

    def read_request_body(env)
      env["rack.input"].read.tap do
        env["rack.input"].rewind
      end
    end
  end
end

