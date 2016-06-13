enforce_on_envs = ["staging", "production"]

if enforce_on_envs.include?(Hanami.env)
  Concierge::Credentials.validate_credentials!({
    atleisure:  %w(username password test_mode),
    jtb:        %w(id user password company url),
    kigo:       %w(subscription_key),
    kigolegacy: %w(username password)
  })
end
