module SAW
  module Entities
    # +SAW::Entities::Country+
    #
    # This entity corresponds to a country that was fetched from the SAW API
    #
    # Attributes
    #
    # +id+   - the ID of the property in SAW database
    # +name+ - name of the country
    class Country
      attr_reader :id, :name

      def initialize(id:, name:)
        @id = id
        @name = name
      end
    end
  end
end
