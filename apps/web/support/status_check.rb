module Support
  class StatusCheck
    include Concierge::JSON

    CONCIERGE_ENDPOINT = "https://concierge.roomorama.com"
    CONNECTION_TIMEOUT = 10

    attr_reader :url

    def initialize(url = CONCIERGE_ENDPOINT)
      @url = url
    end

    def alive?
      raw_response.success?
    end

    def healthy?
      return false unless alive? && body.success?
      body.value["status"] == "ok"
    end

    def version
      return nil unless alive? && body.success?
      body.value["version"]
    end

    def raw_response
      @response ||= http.get("/_ping")
    end

    private

    def body
      @body ||= json_decode(raw_response.body)
    end

    def http
      @http ||= Faraday.new(url: url, request: { timeout: CONNECTION_TIMEOUT }) do |f|
        f.adapter :patron
      end
    end

  end
end
