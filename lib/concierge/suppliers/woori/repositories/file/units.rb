module Woori::Repositories::File
  class Units < Base
    attr_reader :files

    # Initialize a new `Woori::Repositories::File::Units` object.
    #
    # Usage:
    #
    #   Repositories::File::Units.new(files)
    def initialize(files)
      @files = files
    end

    def all
      @units ||= raw_units.map do |unit_hash|
        safe_hash = Concierge::SafeAccessHash.new(unit_hash)
        mapper = Woori::Mappers::RoomoramaUnit.new(safe_hash)
        mapper.build_unit
      end
    end

    def find(unit_id)
      all.find { |u| u.identifier == unit_id }
    end

    def find_all_by_property_id(property_id)
      all.select { |u| u.identifier.start_with?(property_id) }
    end

    private

    # Method doesn't convert `Hash` object to `Concierge::SafeAccessHash`
    # because `decoded_result` is a big object and it doesn't make sense to
    # perform this convertion just for two key access operations.
    def raw_units
      items = []

      files.each do |data_source|
        decoded_result = json_decode(data_source)
        
        units_data = decoded_result.value["data"]
        return [] unless units_data

        file_items = units_data["items"]
        return [] unless file_items

        items = items + file_items
      end

      items
    end
  end
end
