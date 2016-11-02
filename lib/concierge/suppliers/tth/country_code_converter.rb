module THH
  # +THH::CountryCodeConverter+
  #
  # This class acts as a facade between country codes converter library and
  # our source code for abstracting library's entities and using only needed
  # part of the library API.
  class CountryCodeConverter

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

      return if name.empty?

      country = IsoCountryCodes.search_by_name(name) do
        return
      end.first

      country.alpha2
    end
  end
end