# subscribes to +Concierge::Announcer+ events published by the
# +API::Support::SOAPClient+ class.  See that class documentation,
# as well that of the classes under +Concierge::Context+ to understand
# the rationale.

Concierge::Announcer.on(API::Support::SOAPClient::ON_REQUEST) do |endpoint, operation, message|
  soap_request = Concierge::Context::SOAPRequest.new(
    endpoint:  endpoint,
    operation: operation,
    payload:   message
  )

  API.context.augment(soap_request)
end

Concierge::Announcer.on(API::Support::SOAPClient::ON_RESPONSE) do |status, headers, body|
  soap_response = Concierge::Context::SOAPResponse.new(
    status:  status,
    headers: headers,
    body:    body
  )

  API.context.augment(soap_response)
end

Concierge::Announcer.on(API::Support::SOAPClient::ON_FAILURE) do |message, backtrace|
  soap_failure = Concierge::Context::Message.new(
    label:     "SOAP Fault",
    message:   message,
    backtrace: backtrace
  )

  API.context.augment(soap_failure)
end
