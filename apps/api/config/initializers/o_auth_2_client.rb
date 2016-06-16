# subscribes to +Concierge::Announcer+ events published by the
# +API::Support::HTTPClient+ class.  See that class documentation,
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
