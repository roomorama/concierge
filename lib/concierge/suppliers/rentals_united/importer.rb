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

    # Retrieves properties collection for a given owner by +owner_id+
    #
    # Properties which are no longer available will be filtered out.
    #
    # Returns a +Result+ wrapping +Entities::PropertiesCollection+ object
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_properties_collection_for_owner(owner_id)
      fetcher = Commands::PropertiesCollectionFetcher.new(
        credentials,
        owner_id
      )
      fetcher.fetch_properties_collection_for_owner
    end

    # Retrieves locations by given location_ids.
    #
    # Arguments:
    #
    #   * +location_ids+ [Array<String>] ids array of locations to fetch
    #
    # Returns a +Result+ wrapping +Array+ of +Entities::Location+ objects
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_locations(location_ids)
      fetcher = Commands::LocationsFetcher.new(credentials, location_ids)
      fetcher.fetch_locations
    end

    # Retrieves locations - currencies mapping.
    #
    # Returns a +Result+ wrapping +Hash+ with location_id => currency pairs
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_location_currencies
      fetcher = Commands::LocationCurrenciesFetcher.new(credentials)
      fetcher.fetch_location_currencies
    end

    # Retrieves property by its id.
    #
    # Returns a +Result+ wrapping +Entities::Property+ object
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_property(property_id)
      property_fetcher = Commands::PropertyFetcher.new(
        credentials,
        property_id
      )
      property_fetcher.fetch_property
    end

    # Retrieves owner by id
    #
    # Returns a +Result+ wrapping +Entities::Owner+ object
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_owner(owner_id)
      fetcher = Commands::OwnerFetcher.new(credentials, owner_id)
      fetcher.fetch_owner
    end

    # Retrieves availabilities for property by its id.
    #
    # Returns [Array<Entities::Availability>] array with availabilities
    def fetch_availabilities(property_id)
      fetcher = Commands::AvailabilitiesFetcher.new(
        credentials,
        property_id
      )

      fetcher.fetch_availabilities
    end

    # Retrieves season rates for property by its id.
    #
    # Returns [Array<Entities::Season>] array with season rate objects
    def fetch_seasons(property_id)
      fetcher = Commands::SeasonsFetcher.new(credentials, property_id)
      fetcher.fetch_seasons
    end
  end
end
