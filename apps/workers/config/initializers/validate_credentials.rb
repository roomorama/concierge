enforce_on_envs = ["staging", "production"]

if enforce_on_envs.include?(Hanami.env)
  Concierge::Credentials.validate_credentials!({
    sqs: %w(region queue_name access_key_id secret_access_key)
  })
end
