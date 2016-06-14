# subscribes to +Concierge::Announcer+ events published by the
# +API::Support::OAuth2Client+ class.  See that class documentation,
# as well that of the classes under +Concierge::Context+ to understand
# the rationale.

Concierge::Announcer.on(API::Support::OAuth2Client::ON_REQUEST) do |http_method, url, query_string, headers, body|
  network_request = Concierge::Context::NetworkRequest.new(
    method:       http_method,
    url:          url,
    query_string: query_string,
    headers:      headers,
    body:         body
  )

  API.context.augment(network_request)
end

Concierge::Announcer.on(API::Support::OAuth2Client::ON_RESPONSE) do |status, headers, body|
  network_response = Concierge::Context::NetworkResponse.new(
    status:  status,
    headers: headers,
    body:    body
  )

  API.context.augment(network_response)
end

Concierge::Announcer.on(API::Support::OAuth2Client::ON_FAILURE) do |message|
  network_failure = Concierge::Context::NetworkFailure.new(
    message: message
  )

  API.context.augment(network_failure)
end

# Receives a +OAuth2::Client+ object
Concierge::Announcer.on(API::Support::OAuth2Client::ON_TOKEN_REQUEST) do |client, strategy|
  token_request = Concierge::Context::TokenRequest.new(site: client.site,
                                                       client_id: client.id,
                                                       client_secret: client.secret,
                                                       strategy: strategy)

  API.context.augment(token_request)
end

# Receives a +OAuth2::AccessToken+ object
Concierge::Announcer.on(API::Support::OAuth2Client::ON_TOKEN_RECEIVED) do |access_token|
  token_received = Concierge::Context::TokenReceived.new(access_token: access_token.token,
                                                         expires_at: access_token.expires_at,
                                                         params: access_token.params)

  API.context.augment(token_received)
end
