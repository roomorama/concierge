module Web::Support

  # +Web::Support::Authentication+
  #
  # This class is responsible for authenticating requests coming to the Concierge
  # web interface. All requests are authenticated using HTTP Basic Auth,
  # and the username and password combination are controlled by the
  # +CONCIERGE_WEB_AUTHENTICATION+ environment variable. Its format, inspired
  # by that of the +curl(1)+ utility, is:
  #
  #     username:password
  #
  # If the given username and password combination match the content of that
  # environment variable, then the request is successfully authenticated.
  #
  # Usage:
  #
  #     authenticator = Web::Support::Authentication.new("admin", "pwned")
  #     authenticator.authorize? # => false
  class Authentication

    # Simple struct to wrap the username and password combination stored
    # in the +CONCIERGE_WEB_AUTHENTICATION+ environment variable.
    Credentials = Struct.new(:username, :password)

    attr_reader :username, :password

    def initialize(username, password)
      @username = username
      @password = password
    end

    def authorized?
      username == credentials.username && password == credentials.password
    end

    private

    def credentials
      @credentials ||= Credentials.new(*ENV["CONCIERGE_WEB_AUTHENTICATION"].split(":"))
    end
  end

end
