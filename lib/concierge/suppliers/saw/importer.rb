module SAW
  class Importer

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def fetch_countries
      countries_fetcher = Commands::CountriesFetcher.new(credentials)
      countries_fetcher.call
    end
  end
end
