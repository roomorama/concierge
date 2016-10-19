def validate_credentials?
  ENV["VALIDATE_CREDENTIALS"] != "false"
end

if validate_credentials?
  Concierge::Credentials.validate_credentials!({
    sqs: %w(region queue_name access_key_id secret_access_key)
  })
end
