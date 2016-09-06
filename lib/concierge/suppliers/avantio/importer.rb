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

    # Fetches all properties for given host from Avantio
    # Returns the Result wrapping the array of +Avantio::Entities::Accommodation+
    def fetch_properties(host)
      fetcher = Commands::AccommodationsFetcher.new(host.identifier)
      fetcher.call
    end

    # Fetches all descriptions for given host from Avantio
    # Returns the Result wrapping the hash with +Avantio::Entities::Description+
    def fetch_descriptions(host)
      fetcher = Commands::DescriptionsFetcher.new(host.identifier)
      fetcher.call
    end

    # Fetches all occupational rules for given host from Avantio
    # Returns the Result wrapping the hash with +Avantio::Entities::OccupationalRule+
    def fetch_occupational_rules(host)
      fetcher = Commands::OccupationalRulesFetcher.new(host.identifier)
      fetcher.call
    end

    # Fetches all rates for given host from Avantio
    # Returns the Result wrapping the hash with +Avantio::Entities::Rate+
    def fetch_rates(host)
      fetcher = Commands::RatesFetcher.new(host.identifier)
      fetcher.call
    end
  end
end
