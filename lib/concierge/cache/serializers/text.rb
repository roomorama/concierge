class Concierge::Cache
  module Serializers

    # +Concierge::Cache::Serializers::Text+
    #
    # This is default serializer used by +Concierge::Cache+. All content is serialized
    # as a string and the return of a computation is always decoded back to a string.
    class Text

      def encode(value)
        value.to_s
      end

      def decode(value)
        Result.new(value.to_s)
      end

    end
  end
end
