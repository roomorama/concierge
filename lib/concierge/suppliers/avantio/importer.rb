module Avantio
  # +Avantio::Importer+
  #
  # This class wraps supplier API and provides data for building properties.
  #
  # Usage
  #
  #   importer = Avantio::Importer.new
  #   importer.fetch_properties(host)
  #   importer.fetch_descriptions(host)
  class Importer
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Fetches all properties for given host from Avantio
    # Returns the Result wrapping the array of +Avantio::Entities::Accommodation+
    def fetch_properties
      fetcher = Commands::AccommodationsFetcher.new(credentials.code_partner)
      fetcher.call
    end

    # Fetches all descriptions for given host from Avantio
    # Returns the Result wrapping the hash with +Avantio::Entities::Description+
    def fetch_descriptions
      fetcher = Commands::DescriptionsFetcher.new(credentials.code_partner)
      fetcher.call
    end

    # Fetches all occupational rules for given host from Avantio
    # Returns the Result wrapping the hash with +Avantio::Entities::OccupationalRule+
    def fetch_occupational_rules
      fetcher = Commands::OccupationalRulesFetcher.new(credentials.code_partner)
      fetcher.call
    end

    # Fetches all rates for given host from Avantio
    # Returns the Result wrapping the hash with +Avantio::Entities::Rate+
    def fetch_rates
      fetcher = Commands::RatesFetcher.new(credentials.code_partner)
      fetcher.call
    end

    # Fetches all availabilities for given host from Avantio
    # Returns the Result wrapping the hash with +Avantio::Entities::Availability+
    def fetch_availabilities
      fetcher = Commands::AvailabilitiesFetcher.new(credentials.code_partner)
      fetcher.call
    end
  end
end
