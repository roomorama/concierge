module Ciirus
  # +Ciirus::CountryCodeConverter+
  #
  # This class acts as a facade between country codes converter library and
  # our source code for abstracting library's entities and using only needed
  # part of the library API.
  #
  # Some of convertions can be hardcoded with CUSTOM_COUNTRY_NAMES_MAPPING
  # because there is some differences between which names are used in country
  # codes converter library and in Ciirus API.
  class CountryCodeConverter
    CUSTOM_COUNTRY_NAMES_MAPPING = {
      'UK' => 'GB'
    }

    # Returns country code by its name
    #
    # Arguments
    #   * +name+ [String] name of the country
    #
    # Example
    #
    #   CountryCode.code_by_name("Korea")
    #   => "KR"
    #
    # Returns [String] country code or nil
    def code_by_name(name)
      name = name.strip
      return CUSTOM_COUNTRY_NAMES_MAPPING[name] if CUSTOM_COUNTRY_NAMES_MAPPING[name]

      # Try to find country by alpha-2, alpha-3 codes
      country = IsoCountryCodes.find(name) { nil }
      if country.nil?
        standartized_name = prepare_name(name)
        countries = IsoCountryCodes.search_by_name(standartized_name) { [] }
        country = countries.first
      end
      country&.alpha2
    end

    private
    def prepare_name(name)
      CUSTOM_COUNTRY_NAMES_MAPPING.fetch(name, name)
    end
  end
end