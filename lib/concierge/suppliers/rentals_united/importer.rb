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

    # Retrieves location ids with active properties.
    #
    # Locations without active properties will be filtered out.
    def fetch_location_ids
      fetcher = Commands::LocationIdsFetcher.new(credentials)
      fetcher.fetch_location_ids
    end

    # Retrieves locations by given location_ids.
    #
    # Arguments:
    #
    #   * +location_ids+ [Array<String>] ids array of locations to fetch
    #
    # Returns [Array<Entities::Location>] array of location objects
    def fetch_locations(location_ids)
      fetcher = Commands::LocationsFetcher.new(credentials, location_ids)
      fetcher.fetch_locations
    end

    # Retrieves locations - currencies mapping.
    #
    # Returns [Hash] hash with location_id => currency key-values
    def fetch_location_currencies
      fetcher = Commands::LocationCurrenciesFetcher.new(credentials)
      fetcher.fetch_location_currencies
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
    def fetch_property(property_id, location)
      property_fetcher = Commands::PropertyFetcher.new(
        credentials,
        property_id,
        location
      )
      property_fetcher.fetch_property
    end
  end
end
