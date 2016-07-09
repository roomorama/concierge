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
      client = Concierge::HTTPClient.new("http://localhost:9292")
      result = client.get("/fetch_properties")
      if result.success?
        json = JSON.parse(result.value.body)
        Result.new(json['result'])
      else
        result
      end
    end

    def json_to_property(json)
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
  end
end
