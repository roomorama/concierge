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

    def fetch_properties_by_countries(countries)
      countries.map do |country| 
        result = fetch_properties_by_country(country)
        result.success? ? result.value : []
      end.flatten
    end

    def fetch_detailed_property(property_id)
      property_fetcher = Commands::DetailedPropertyFetcher.new(credentials)
      property_fetcher.call(property_id)
    end
  end
end
