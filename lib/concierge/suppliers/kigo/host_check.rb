module Kigo
  class HostCheck
    include Concierge::JSON

    attr_reader :property_id, :request_handler

    def initialize(property_id, request_handler)
      @property_id     = property_id
      @request_handler = request_handler
    end

    def deactivated?
      result = http.post(endpoint, json_encode(fake_params), { "Content-Type" => "application/json" })

      return unless result.success?

      payload = json_decode(result.value.body)

      payload.value["API_RESULT_TEXT"] =~ /deactivated/
    end

    private

    def endpoint
      request_handler.endpoint_for(Kigo::Price::API_METHOD)
    end

    def http
      request_handler.http_client
    end

    def fake_params
      params = {
        property_id: property_id,
        check_in:    date.to_s,
        check_out:   (date + 10).to_s,
        guests:      2
      }
      request_handler.build_compute_pricing(params)
    end

    def date
      Date.today + 30
    end
  end
end