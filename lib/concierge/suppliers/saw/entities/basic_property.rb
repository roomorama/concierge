module SAW
  module Entities
    # +SAW::Entities::BasicProperty+
    #
    # This entity corresponds to a property that was fetched from the SAW API
    #
    # +SAW::Entities::BasicProperty+ is different from
    # +SAW::Entities::DetailedProperty+: some of property attributes are
    # different
    #
    # Attributes
    #
    # +internal_id+   - the ID of the property in SAW database
    # +type+          - room type
    # +title+         - the short title of the property
    # +description+   - the description of the property
    # +lon+           - address longitude
    # +lat+           - address latitude
    # +city+          - city in which property located in
    # +neighborhood+  - city neighborhood (region) in which property located in
    # +country_code+  - code of the country in which property located in
    # +currency_code+ - currency indicating that booking requests for this
    #                   property should be performed using exactly this
    #                   currency
    # +nightly_rate+  - rate needed to book this property per one night
    # +weekly_rate+   - rate needed to book this property per one week
    # +monthly_rate+  - rate needed to book this property per one month
    # +multi_unit+    - boolean flag indicating that property is multi unit
    class BasicProperty
      attr_reader :internal_id, :type, :title, :description, :lon, :lat,
                  :city, :neighborhood, :country_code, :currency_code,
                  :nightly_rate, :weekly_rate, :monthly_rate

      def initialize(attrs = {})
        @internal_id   = attrs[:internal_id]
        @type          = attrs[:type]
        @title         = attrs[:title]
        @description   = attrs[:description]
        @lon           = attrs[:lon]
        @lat           = attrs[:lat]
        @city          = attrs[:city]
        @neighborhood  = attrs[:neighborhood]
        @country_code  = attrs[:country_code]
        @currency_code = attrs[:currency_code]
        @nightly_rate  = attrs[:nightly_rate]
        @weekly_rate   = attrs[:weekly_rate]
        @monthly_rate  = attrs[:monthly_rate]
        @multi_unit    = attrs[:multi_unit]
      end

      def multi_unit?
        !!@multi_unit
      end
    end
  end
end
