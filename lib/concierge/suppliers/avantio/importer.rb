module Avantio
  # +Avantio::Importer+
  #
  # This class wraps supplier API and provides data for building properties.
  #
  # Usage
  #
  #   importer = Avantio::Importer.new(credentials)
  #   importer.fetch_properties(host)
  #   importer.fetch_images
  #   importer.fetch_description
  class Importer

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Fetches all properties for given host from Ciirus API
    # Returns the Result wrapping the array of Ciirus::Entities::Property.
    def fetch_properties()
      fetcher = Commands::AccommodationsFetcher.new(credentials)
      fetcher.call
    end

  end
end