if Hanami.env == "production"
  Credentials.validate_credentials!({
    atleisure:  %w(username password),
    jtb:        %w(id user password company),
    kigo:       %w(subscription_key),
    kigolegacy: %w(username password)
  })
end
