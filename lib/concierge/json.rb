module Concierge
  module JSON

    PARSING_ERROR = "json.parsing_error"

    # Encodes data to JSON.
    #
    # +data+: a Hash
    def json_encode(data)
      Yajl::Encoder.encode(data)
    end

    # Decodes a JSON string or stream given to a Ruby data-structure.
    # Supports IO streams (StringIO, file, socket, etc) or String.
    #
    # Returns a +Result+ instance. Check its success to be able to properly
    # handle errors.
    def json_decode(json_source)
      Result.new(Yajl::Parser.parse(json_source))
    rescue Yajl::ParseError => err
      announce_parsing_error(err)
      message = ["Error: #{err.message}", json_source.to_s].join("\n")
      Result.error(:invalid_json_representation)
    end

    private

    def announce_parsing_error(error)
      Concierge::Announcer.trigger(PARSING_ERROR, error.message)
    end

  end
end
