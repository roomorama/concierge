module Web::Support

  # +Web::Support::StatusCheck+
  #
  # The status check class is responsible for wrapping the behaviour of the
  # dashboard page, which indicates whether or not Concierge's API is live
  # and healthy.
  #
  # The definition of being alive and healthy is:
  #
  # * if the concierge endpoint was reached and a response sucess response
  #   is returned, then concierge is alive;
  # * if the response body accords to expectations, then concierge is healthy.
  #
  # Usage
  #
  #   check = Web::Support::StatusCheck.new
  #   check.alive?  # => true
  #   check.version # => "0.1.4"
  #
  # This class relies on the +/_ping+ endpoint of the Concierge API, which is
  # used by the load balancer for instance health check. In the future, more data
  # could be returned in that endpoint to allow a more detailed analysis.
  class StatusCheck
    include Concierge::JSON

    PING_ENDPOINT = "/_ping"

    attr_reader :url

    # url - the Concierge API URL. Uses the staging API on the staging environment,
    #       defaulting to production on all other environments.
    def initialize(url = concierge_url)
      @url = url
    end

    def alive?
      response.success?
    end

    def healthy?
      return false unless alive? && json_body.success?
      json_body.value["status"] == "ok"
    end

    def version
      return nil unless alive? && json_body.success?
      json_body.value["version"]
    end

    def response
      @response ||= http.get(PING_ENDPOINT)
    end

    private

    def json_body
      @body ||= json_decode(body)
    end

    def body
      @body ||= response.success? && response.value.body
    end

    def http
      @http ||= Concierge::HTTPClient.new(url)
    end

    def concierge_url
      ENV['CONCIERGE_URL']
    end

  end
end
