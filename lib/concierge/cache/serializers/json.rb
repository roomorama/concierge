require_relative "../../json"

class Concierge::Cache
  module Serializers

    # +Concierge::Cache::Serializers::JSON+
    #
    # This serializer adds support to JSON content in the cache. Its most common
    # use case is when the content to be cached is a Ruby +Hash+: the data structure
    # is transformed into a JSON string before storage and then transformed back into
    # a +Hash+ when loading from the cache.
    #
    # Note that as Ruby hashes are completely dynamic data structures, there is no way
    # to guarantee that the decoded Hash will be exactly in the same format as the
    # original one. Therefore, it is advisable to use this serializer **only for Hashes
    # where the data types for each key-value exist in the JSON notation**.
    #
    # As a consequence of the above, if a +Hash+ has keys as symbols, they will later
    # be de-serialized as strings.
    class JSON
      include Concierge::JSON

      def encode(value)
        json_encode(value)
      end

      def decode(value)
        json_decode(value)
      end

    end
  end
end
