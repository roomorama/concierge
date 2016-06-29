module Ciirus
  # +Ciirus::ResponseParser+
  #
  # This class is intended to convert all response data from Ciirus API to a hash.
  # `Concierge::SafeAccessHash` is used as hash implemetation to provide
  # safe access to hash keys and values
  class ResponseParser
    # Convert `result_body` response to a safe hash
    #
    # Example:
    #
    #   hash = ResponseParser.to_hash(soap_client_response)
    #
    # Returns `Concierge::SafeAccessHash` object
    def to_hash(result_body)
      safe_hash(result_body)
    end

    private

    def safe_hash(usual_hash)
      Concierge::SafeAccessHash.new(usual_hash)
    end
  end
end