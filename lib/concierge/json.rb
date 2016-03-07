module Concierge
  module JSON

    # Encodes data to JSON.
    #
    # +data+: a Hash
    def json_encode(data)
      Yajl::Encoder.encode(data)
    end

    # Decodes a JSON string given to a Ruby data-structure.
    #
    # Returns a +Result+ instance. Check its success to be able to properly
    # handle errors.
    def json_decode(json_string)
      Result.new(Yajl::Parser.parse(json_string))
    rescue Yajl::ParseError => err
      message = ["Error: #{err.message}", json_string.to_s].join("\n")
      Result.error(:invalid_json_representation, err.message)
    end

  end
end
