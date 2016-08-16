module SAW
  # +SAW::ResponseParser+
  #
  # This class is intended to convert all response data from SAW API to a hash.
  # `Concierge::SafeAccessHash` is used as hash implemetation to provide
  # safe access to hash keys and values
  class ResponseParser
    # Convert `result_body` response to a hash
    # `Nori` library is used as XML to Hash translator
    #
    # Example:
    #
    #   hash = ResponseParser.to_hash(raw_xml_response)
    #
    # Returns `Concierge::SafeAccessHash` object
    def to_hash(result_body)
      safe_hash(parse_hash(result_body))
    end

    private
    def safe_hash(usual_hash)
      Concierge::SafeAccessHash.new(usual_hash)
    end

    def parse_hash(response)
      Nori.new.parse(response)
    end
  end
end
