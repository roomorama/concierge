enforce_on_envs = ["staging", "production"]

if enforce_on_envs.include?(Hanami.env)
  Concierge::Credentials.validate_credentials!({
    atleisure:     %w(username password test_mode),
    jtb:           %w(api.id api.user api.password api.company api.url
                     sftp.user_id sftp.password sftp.port sftp.host
                     sftp.tmp_path),
    kigo:          %w(subscription_key),
    kigolegacy:    %w(username password),
    waytostay:     %w(client_id client_secret url token_url),
    ciirus:        %w(url username password),
    saw:           %w(username password url),
    poplidays:     %w(url client_key passphrase),
    rentalsunited: %w(username password url),
    avantio:       %w(username password)
  })
end
