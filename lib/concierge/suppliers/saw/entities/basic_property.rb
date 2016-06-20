module SAW
  module Entities
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
