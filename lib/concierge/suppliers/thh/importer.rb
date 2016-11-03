module THH
  # +THH::Importer+
  #
  # This class wraps supplier API and provides data for building properties.
  class Importer

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Fetches all properties from THH API
    # Returns the Result wrapping the array of Hash.
    def fetch_properties
      fetcher = Commands::PropertiesFetcher.new(credentials)
      fetcher.call
    end
  end
end