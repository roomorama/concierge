module Woori
  # +Woori::Importer+
  #
  # This class provides an interface for the bulk import of Woori properties.
  #
  # Usage
  #
  #   importer = Woori::Importer.new(credentials)
  #   importer.fetch_properties
  class Importer

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def fetch_properties
      properties_fetcher = Commands::PropertiesFetcher.new(credentials)
      properties_fetcher.call
    end
  end
end
