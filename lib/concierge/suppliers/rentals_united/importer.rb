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
    #
    # Returns a +Result+ wrapping +Array+ of +String+ location ids
    # Returns a +Result+ with +Result::Error+ when operation fails
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

    # Retrieves property ids by location id.
    #
    # IDs of properties which are no longer available will be filtered out.
    #
    # Returns a +Result+ wrapping +Array+ of +String+ property ids
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_property_ids(location_id)
      properties_fetcher = Commands::PropertyIdsFetcher.new(
        credentials,
        location_id
      )
      properties_fetcher.fetch_property_ids
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

    # Retrieves properties by given ids
    #
    # Returns a +Result+ wrapping +Array+ of +Entities::Property+ objects
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_properties_by_ids(property_ids)
      properties = property_ids.map do |property_id|
        result = fetch_property(property_id)

        return result unless result.success?

        result.value
      end.compact

      Result.new(properties)
    end

    # Retrieves owners
    #
    # Returns a +Result+ wrapping +Array+ of +Entities::Owner+ objects
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_owners
      fetcher = Commands::OwnersFetcher.new(credentials)
      fetcher.fetch_owners
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

    # Retrieves rates for property by its id.
    def fetch_rates(property_id)
      fetcher = Commands::RatesFetcher.new(credentials, property_id)
      fetcher.fetch_rates
    end
  end
end
