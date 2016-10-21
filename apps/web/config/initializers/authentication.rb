USERNAME_MIN_LENGTH = 4
PASSWORD_MIN_LENGTH = 10

def validate_concierge_web_credentials?
  ENV["VALIDATE_CONCIERGE_WEB_CREDENTIALS"] == "true"
end

class InvalidCredentialsError < StandardError
  def initialize(value, format)
    super("Invalid credentials on CONCIERGE_WEB_AUTHENTICATION. " +
          "Environment variable is set to #{value}. " +
          "Expected format: #{format}. " +
          "Username must be at least #{USERNAME_MIN_LENGTH} characters long. " +
          "Password must be at least #{PASSWORD_MIN_LENGTH} characters long."
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
if validate_concierge_web_credentials?
  credentials = ENV["CONCIERGE_WEB_AUTHENTICATION"].to_s
  username, password = credentials.split(":").map(&:to_s)

  if username.size < USERNAME_MIN_LENGTH || password.size < PASSWORD_MIN_LENGTH
    raise InvalidCredentialsError.new(credentials, '#{username}:#{password}')
  end
end
