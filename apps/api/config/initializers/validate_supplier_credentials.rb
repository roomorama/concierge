enforce_on_envs = ["staging", "production"]

if enforce_on_envs.include?(Hanami.env)
  Concierge::Credentials.validate_credentials!({
    atleisure:  %w(username password test_mode),
    jtb:        %w(id user password company url),
    kigo:       %w(subscription_key),
    kigolegacy: %w(username password),
    waytostay:  %w(client_id client_secret url token_url),
    ciirus:     %w(url username password),
    saw:        %w(username password url)
  })
end
