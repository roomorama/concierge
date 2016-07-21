module Woori
  # +Woori::Importer+
  #
  # This class provides an interface for the bulk import of Woori properties.
  #
  # Usage
  #
  #   importer = Woori::Importer.new(credentials)
  #   importer.fetch_properties(updated_at, limit, offset)
  #   importer.fetch_units("w_w0104006")
  class Importer
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def fetch_properties(updated_at, limit, offset)
      properties_fetcher = Commands::PropertiesFetcher.new(credentials)
      properties_fetcher.call(updated_at, limit, offset)
    end

    def fetch_units(property_id)
      properties_fetcher = Commands::UnitsFetcher.new(credentials)
      properties_fetcher.call(property_id)
    end
    
    def fetch_all_units(updated_at, limit, offset)
      properties_fetcher = Commands::UnitsFetcher.new(credentials)
      properties_fetcher.call(updated_at, limit, offset)
    end
  end
end
