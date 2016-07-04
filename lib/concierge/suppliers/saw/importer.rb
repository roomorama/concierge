module SAW
  # +SAW::Importer+
  #
  # This class wraps supplier API and provides data for building properties.
  #
  # `SAW::Importer` returns properties and countries.
  # There are corresponsing PORO-entities which describe these domain models.
  #
  # A `SAW::Entities::DetailedProperty` object is different from the 
  # `SAW::Entities::BasicProperty` object and we can't say that one of them is 
  # a full version of the property and the second one is a light version
  # because there are some attributes which present in `BasicProperty` but 
  # missed in `DetailedProperty` and vise versa.
  #
  # Usage
  #
  #   importer = SAW::Importer.new(credentials)
  #   importer.fetch_countries
  #   importer.fetch_properties
  #   importer.fetch_properties_by_country(country)
  #   importer.fetch_properties_by_countries(countries)
  #   importer.fetch_detailed_property
  class Importer

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Retrieves the list of countries for further usage.
    #
    # SAW API requires country/cityregion information for its search method.
    # There is also an endpoint which returns all properties, but we can't use
    # it since it includes `On Request` properties and we would end up with the
    # solution when we have to deal with additional filtering of these
    # properties.
    # Sticking with providing `country` is a way more easier.
    #
    # Returns [Array<SAW::Entities::Country>] array with available countries
    def fetch_countries
      countries_fetcher = Commands::CountriesFetcher.new(credentials)
      countries_fetcher.call
    end

    # Retrieves the list of properties in a given country
    #
    # Returns [Array<SAW::Entities::BasicProperty>]
    def fetch_properties_by_country(country)
      properties_fetcher = Commands::CountryPropertiesFetcher.new(credentials)
      properties_fetcher.call(country)
    end

    # Retrieves the list of properties in given countries
    # Method ignores failed results, so only country property lists with
    # successful results will be included in returning array.
    #
    # Returns [Array<SAW::Entities::BasicProperty>]
    def fetch_properties_by_countries(countries)
      countries.map do |country| 
        result = fetch_properties_by_country(country)
        result.success? ? result.value : []
      end.flatten
    end

    # Retrieves property with extended information.
    #
    # Returns [Array<SAW::Entities::DetailedProperty>]
    def fetch_detailed_property(property_id)
      property_fetcher = Commands::DetailedPropertyFetcher.new(credentials)
      property_fetcher.call(property_id)
    end
  end
end
