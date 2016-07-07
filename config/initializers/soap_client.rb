Concierge::Announcer.on(Concierge::SOAPClient::ON_REQUEST) do |endpoint, operation, message|
  soap_request = Concierge::Context::SOAPRequest.new(
    endpoint:  endpoint,
    operation: operation,
    payload:   message
  )

  Concierge.context.augment(soap_request)
end

Concierge::Announcer.on(Concierge::SOAPClient::ON_RESPONSE) do |status, headers, body|
  soap_response = Concierge::Context::SOAPResponse.new(
    status:  status,
    headers: headers,
    body:    body
  )

  Concierge.context.augment(soap_response)
end

Concierge::Announcer.on(Concierge::SOAPClient::ON_FAILURE) do |message, backtrace|
  soap_failure = Concierge::Context::Message.new(
    label:     "SOAP Fault",
    message:   message,
    backtrace: backtrace
  )

  Concierge.context.augment(soap_failure)
end
