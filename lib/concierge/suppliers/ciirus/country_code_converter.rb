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
      'UK'           => 'GB',
      'U.S.A.'       => 'US',
      'U.S.A'        => 'US',
      'UNITE STATES' => 'US',
      'Osceola'      => 'US',
      'Polk'         => 'US',
      'Larnaca'      => 'CY',
      'Cyrus'        => 'CY',
      'Paralimni'    => 'CY',
      'Famagusta'    => 'CY'
    }

    # Finds country code by its name.
    #
    # Arguments
    #   * +name+ [String] name of the country
    #
    # Example
    #
    #   converter = CountryCodeConverter.new
    #   country_code = converter.code_by_name("Korea")
    #   country_code.value # => "KR"
    #
    # Returns +Result+ wrapping country code
    def code_by_name(name)
      name = name.to_s.strip

      return error_result(name) if name.empty?
      return Result.new(CUSTOM_COUNTRY_NAMES_MAPPING[name]) if CUSTOM_COUNTRY_NAMES_MAPPING[name]

      # Try to find country by alpha-2, alpha-3 codes
      country = IsoCountryCodes.find(name) do
        # Try to find country by name
        IsoCountryCodes.search_by_name(name) do
          return error_result(name)
        end.first
      end

      Result.new(country.alpha2)
    end

    private

    def error_result(name)
      message = "Couldn't find country code for country: `#{name}`"
      Result.error(:unknown_country, data = message)
    end
  end
end