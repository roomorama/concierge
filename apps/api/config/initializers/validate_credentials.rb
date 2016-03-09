if Hanami.env == "production"
  Concierge::Credentials.validate_credentials!({
    atleisure:  %w(username password),
    jtb:        %w(id user password company url),
    kigo:       %w(subscription_key),
    kigolegacy: %w(username password)
  })
end
