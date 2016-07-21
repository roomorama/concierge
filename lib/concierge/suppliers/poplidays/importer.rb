module Poplidays
  # +Poplidays::Importer+
  #
  # This class wraps supplier API and provides data for building properties.
  #
  # Usage
  #
  #   importer = Poplidays::Importer.new(credentials)
  #   importer.fetch_properties
  class Importer

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def fetch_properties
      fetcher = Commands::LodgingsFetcher.new(credentials)
      fetcher.call
    end

    def fetch_property_details(property_id)
      fetcher = Commands::LodgingFetcher.new(credentials)
      fetcher.call(property_id)
    end

    def fetch_availabilities(property_id)
      fetcher = Commands::AvailabilitiesFetcher.new(credentials)
      fetcher.call(property_id)
    end
  end
end