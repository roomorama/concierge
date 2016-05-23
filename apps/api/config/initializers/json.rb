Concierge::Announcer.on(Concierge::JSON::PARSING_ERROR) do |error_message|
  parse_error = Concierge::Context::JSONParsingError.new(
    message: error_message
  )

  API.context.augment(parse_error)
end
