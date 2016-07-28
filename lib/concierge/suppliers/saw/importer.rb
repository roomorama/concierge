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
  #   importer.fetch_properties_by_country(country)
  #   importer.fetch_properties_by_countries(countries)
  #   importer.fetch_detailed_property(property_id)
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
    # Returns a +Result+ wrapping +Array+ of +SAW::Entities::Country+
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_countries
      countries_fetcher = Commands::CountriesFetcher.new(credentials)
      countries_fetcher.call
    end

    # Retrieves the list of properties in a given country
    #
    # Returns a +Result+ wrapping +Array+ of +SAW::Entities::BasicProperty+
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_properties_by_country(country)
      properties_fetcher = Commands::CountryPropertiesFetcher.new(credentials)
      properties_fetcher.call(country)
    end

    # Retrieves the list of available properties in a given country
    # Available means those which doesn't have `on_request` attribute
    #
    # Returns a +Result+ wrapping +Array+ of +SAW::Entities::BasicProperty+
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_available_properties_by_country(country)
      result = fetch_properties_by_country(country)

      if result.success?
        all_properties = result.value
        available_properties = all_properties.reject { |p| p.on_request? }
        Result.new(available_properties)
      else
        result
      end
    end

    # Retrieves the list of properties in given countries
    # In case if request to one of the countries fails, method stops its
    # execution and returns a result with a failure.
    #
    # Returns a +Result+ wrapping +Array+ of +SAW::Entities::BasicProperty+
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_properties_by_countries(countries)
      properties = countries.map do |country|
        result = fetch_properties_by_country(country)

        return result unless result.success?

        result.value
      end.flatten

      Result.new(properties)
    end

    # Retrieves the list of available properties in given countries
    # In case if request to one of the countries fails, method stops its
    # execution and returns a result with a failure.
    #
    # Returns a +Result+ wrapping +Array+ of +SAW::Entities::BasicProperty+
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_available_properties_by_countries(countries)
      properties = countries.map do |country|
        result = fetch_available_properties_by_country(country)

        return result unless result.success?

        result.value
      end.flatten

      Result.new(properties)
    end

    # Retrieves property with extended information.
    #
    # Returns a +Result+ wrapping +SAW::Entities::DetailedProperty+ object
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def fetch_detailed_property(property_id)
      property_fetcher = Commands::DetailedPropertyFetcher.new(credentials)
      property_fetcher.call(property_id)
    end
  end
end
