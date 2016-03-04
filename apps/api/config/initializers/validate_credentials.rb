if Hanami.env == "production"
  Credentials.validate_credentials!({
    atleisure: %w(username password)
  })
end
