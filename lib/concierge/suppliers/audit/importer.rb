module Audit
  # +Audit::Importer+
  #
  # This class wraps supplier API and provides data for building properties.
  #
  # Usage
  #
  #   importer = Audit::Importer.new(credentials)
  #   importer.fetch_properties
  #
  #   => #<Result:0x007ff5fc624dd8 @result=[{'HouseCode' => 'XX-12345-67', ...}, ...]
  class Importer
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # retrieves the list of properties
    def fetch_properties
      client = Concierge::HTTPClient.new(credentials.host)
      result = client.get(credentials.fetch_properties_endpoint)
      if result.success?
        json = JSON.parse(result.value.body)
        Result.new(json['result'])
      else
        result
      end
    end

    def json_to_property(json)
      # `Roomorama::Property.load` prefer absolute urls, but our fixture `url` values are relative
      # make it happy
      fix_relative_urls!(URI.join(credentials.host, credentials.fetch_properties_endpoint), json)

      Roomorama::Property.load(Concierge::SafeAccessHash.new json).tap do |property_result|
        if property_result.success?
          property = property_result.value
          property.update_calendar(json['availability_dates'])
          property.units.each do |unit|
            if unitjson = json['units'].find {|h| h['identifier'] == unit.identifier }
              unit.update_calendar(unitjson['availability_dates'])
            end
          end
        end
      end
    end

    private

    def fix_relative_urls!(base_uri, object)
      case object
      when Hash
        object.each do |key, value|
          if key == 'url'
            object[key] = URI.join(base_uri, URI.escape(value)).to_s
          elsif value.kind_of?(Hash) || value.kind_of?(Array)
            fix_relative_urls!(base_uri, value)
          end
        end
      when Array
        object.each {|item| fix_relative_urls!(base_uri, item) }
      end
    end
  end
end
