module Woori::Repositories::File
  class Properties < Base
    attr_reader :file

    def initialize(file_path)
      @file = File.new(file_path, 'r')
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
      json_decode(file) 
    end

    def properties_hash
      properties_result.value
    end
  end
end
