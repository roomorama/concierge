enforce_on_envs = ["staging", "production"]

class InvalidCredentialsError < StandardError
  def initialize(value, format)
    super("Invalid credentials on CONCIERGE_WEB_AUTHENTICATION. " +
          "Environment variable is set to #{value}. " +
          "Expected format: #{format}. " +
          "Username must be at least 4 characters long. Password must be at least 10 characters long."
    )
  end
end

# the CONCIERGE_WEB_AUTHENTICATION environment variable defines the credentials to be
# applied for anyone who wishes to access the web app. Therefore, it is worth to make sure
# it is properly set on production environments.
#
# Apart from the presence checks performed by +Concierge::Environment+, this initializer
# ensures that the variable follows the expected format and that the username and password
# meets minimum length requirements.
if enforce_on_envs.include?(Hanami.env)
  credentials = ENV["CONCIERGE_WEB_AUTHENTICATION"].to_s
  username, password = credentials.split(":").map(&:to_s)

  if username.size < 3 || password.size < 9
    raise InvalidCredentialsError.new(credentials, '#{username}:#{password}')
  end
end
