module Kigo
  # +Kigo::HostCheck+
  #
  # KigoLegacy supplier doesn't provide data about host status (active/deactivated)
  # in way of discussion Kigo's support offer workaround by calling price quotation
  # to define is host deactivated
  class HostCheck
    include Concierge::JSON

    attr_reader :property_ids, :request_handler

    def initialize(property_ids, request_handler)
      @property_ids    = property_ids
      @request_handler = request_handler
    end

    def active?
      res = nil
      active = property_ids.any? do |id|
        res = property_active?(id)
        res.success? && res.value == true
      end
      return Result.new(true) if active
      return Result.new(false) if res.success?
      res
    end

    def property_active?(property_id)
      result = http.post(endpoint, json_encode(fake_params(property_id).value), { "Content-Type" => "application/json" })

      if result.success?
        payload = json_decode(result.value.body)
        is_active = !payload.value["API_RESULT_TEXT"].include?("deactivated")
        Result.new(is_active)
      else
        result
      end
    end

    private

    def endpoint
      request_handler.endpoint_for(Kigo::Price::API_METHOD)
    end

    def http
      request_handler.http_client
    end

    def fake_params(property_id)
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
