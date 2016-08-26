require 'open-uri'

module Woori::Repositories::File
  class Properties < Base
    attr_reader :data_source

    # Initialize a new `Woori::Repositories::File::Properties` object.
    #
    # It's possible for the `location` argument to be:
    #
    #   * path to a local file in the filesystem
    #   * url to download the file
    #
    # Usage:
    #
    #   Repositories::File::Properties.new("/data/properties.json")
    #   Repositories::File::Properties.new("http://site.co/properties.json")
    def initialize(location)
      @data_source = open(location)
    end

    def all
      raw_properties.map do |propery_hash|
        safe_hash = Concierge::SafeAccessHash.new(propery_hash)
        mapper = Woori::Mappers::RoomoramaProperty.new(safe_hash)
        mapper.build_property
      end
    end
    
    private

    # Method doesn't convert `Hash` object to `Concierge::SafeAccessHash`
    # because `propery_hash` is a big object and it doesn't make sense to
    # perform this convertion just for two key access operations.
    def raw_properties
      properties_data = properties_hash["data"]
      return [] unless properties_data

      items = properties_data["items"]
      return [] unless items

      items
    end

    def properties_result
      json_decode(data_source)
    end

    def properties_hash
      properties_result.value
    end
  end
end
