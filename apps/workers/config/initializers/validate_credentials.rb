enforce_on_envs = ["staging", "production"]

if enforce_on_envs.include?(Hanami.env)
  Concierge::Credentials.validate_credentials!({
    aws: %w(region access_key_id secret_access_key sqs_queue_name s3_bucket)
  })
end
