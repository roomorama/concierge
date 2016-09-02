module RentalsUnited
  # +RentalsUnited::Importer+
  #
  # This class wraps supplier API and provides data for building properties.
  #
  # Usage
  #
  #   importer = RentalsUnited::Importer.new(credentials)
  class Importer

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Retrieves cities with active properties.
    #
    # Cities without active properties will be filtered out.
    def fetch_cities
      cities_fetcher = Commands::CitiesFetcher.new(credentials)
      cities_fetcher.fetch_cities
    end

    # Retrieves property ids by location id.
    #
    # IDs of properties which are no longer available will be filtered out.
    def fetch_property_ids(location_id)
      properties_fetcher = Commands::PropertyIdsFetcher.new(
        credentials,
        location_id
      )
      properties_fetcher.fetch_property_ids
    end

    # Retrieves property by its id.
    def fetch_property(property_id)
      property_fetcher = Commands::PropertyFetcher.new(
        credentials,
        property_id
      )
      property_fetcher.fetch_property
    end
  end
end
