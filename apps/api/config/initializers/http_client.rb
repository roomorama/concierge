# configures request hooks as supported by +Concierge::HTTPClient+.
# See that class documentation, as well that of the classes under
# +Concierge::Context+ to understand the rationale.

Concierge::HTTPClient.on_request do |http_method, url, query_string, headers, body|
  network_request = Concierge::Context::NetworkRequest.new(
    method:       http_method,
    url:          url,
    query_string: query_string,
    headers:      headers,
    body:         body
  )

  API.context.augment(network_request)
end

Concierge::HTTPClient.on_response do |status, headers, body|
  network_response = Concierge::Context::NetworkResponse.new(
    status:  status,
    headers: headers,
    body:    body
  )

  API.context.augment(network_response)
end

Concierge::HTTPClient.on_error do |message|
  network_failure = Concierge::Context::NetworkFailure.new(
    message: message
  )

  API.context.augment(network_failure)
end
