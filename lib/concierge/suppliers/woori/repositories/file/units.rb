module Woori::Repositories::File
  class Units < Base
    attr_reader :files

    def initialize(files_path)
      @files = files_path.map { |file_path| File.new(file_path, 'r') }
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

    def raw_units
      items = []

      files.each do |file|
        decoded_result = json_decode(file)
        
        units_data = decoded_result.value["data"]
        return [] unless units_data

        file_items = units_data["items"]
        return [] unless file_items

        items = items + file_items
      end

      require 'byebug'; byebug
      items
    end
  end
end
