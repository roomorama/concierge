require "delegate"

module Concierge

  # +Concierge::RequestLogger+
  #
  # Hanami does not yet support request logging as of the version currently being
  # used in Concierge (0.7.2). Therefore, this class aims to log every authenticated
  # request sent to Concierge, with the goal of aiding the debugging and analysis
  # process when Concierge is deployed to production and staging environments.
  #
  # This class supports basic request logging, displaying the HTTP request method
  # and URL path requested, as well as the request body, if any.
  #
  # Usage:
  #
  #   logger = Concierge::RequestLogger.new("api")
  #   logger.log(
  #     http_method: "POST",
  #     status: 200,
  #     path: "/jtb/quote",
  #     query: "pretty=true",
  #     time: 1.23, # seconds
  #     request_body: { foo: "bar" }
  #   )
  #
  # Requests are logged by default on the +log/<name>.<env>+ file.
  #
  # See +API::Middlewares::RequestLogging+ to check how this class is used in
  # the request lifecycle.
  #
  # TODO remove this class when Hanami ships with a more robust form of request
  # logging.
  class RequestLogger
    include Concierge::JSON

    attr_reader :engine

    # Creates a new +Concierge::RequestLogger+ instance. Uses a Ruby +Logger+ instance
    # by default to log requests on info level.
    #
    # engine - the logger engine. Must respond to +info+.
    def initialize(engine = default_engine)
      @engine = engine
    end

    def log(http_method:, status:, path:, query:, time:, request_body:)
      message = format(http_method, status, path, query, time, request_body)
      engine.info(message)
    end

    private

    def format(http_method, status, path, query, time, request_body)
      summary = "%s %s | T: %.2fs | S: %s" % [http_method.upcase, with_query_string(path, query), time.to_f, status]

      if request_body.to_s.empty?
        summary
      else
        [summary, "\n", request_body].join
      end
    end

    def with_query_string(path, query)
      if query.to_s.empty?
        path
      else
        [path, "?", query].join
      end
    end

    def default_engine
      output = Hanami.root.join("log", [Hanami.env, ".log"].join).to_s
      Logger.new(output)
    end
  end

end
