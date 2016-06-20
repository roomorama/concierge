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

    def fetch_properties_by_country(country)
      properties_fetcher = Commands::CountryPropertiesFetcher.new(credentials)
      properties_fetcher.call(country)
    end

    def fetch_properties_by_countries(counties)
      countries.map do |country| 
        fetch_properties_by_country(country)
      end.flatten
    end
  end
end
