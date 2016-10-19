def validate_credentials?
  ENV["VALIDATE_CREDENTIALS"] == "true"
end

if validate_credentials?
  Concierge::Credentials.validate_credentials!({
    atleisure:     %w(username password test_mode),
    jtb:           %w(id user password company url),
    kigo:          %w(subscription_key),
    kigolegacy:    %w(username password),
    waytostay:     %w(client_id client_secret url token_url),
    ciirus:        %w(url username password),
    saw:           %w(username password url),
    poplidays:     %w(url client_key passphrase),
    rentalsunited: %w(username password url)
  })
end
