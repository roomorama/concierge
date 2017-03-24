module RentalsUnited
  module Converters
    # +RentalsUnited::Converters::CountryCode+
    #
    # This class acts as a facade between country codes converter library and
    # our source code for abstracting library's entities and using only needed
    # part of the library API.
    class CountryCode
      class << self
        # Returns country code by its name
        #
        # Arguments
        #   * +name+ [String] name of the country
        #
        # Example
        #
        #   CountryCode.code_by_name("Korea, Republic of")
        #   => "KR"
        #
        # Returns [String] country code
        def code_by_name(name)
          country = IsoCountryCodes.search_by_name(resolve(name)).first
          (country && country.alpha2).to_s
        end

        private

        # resolves conflicts for mismatching countries from the ISO 3366-1 list
        def resolve(name)
          countries_not_in_iso.fetch(name) { name }
        end

        def countries_not_in_iso
          {
            'Canary Islands' => 'Spain',
            'Vietnam'        => 'Viet nam'
          }
        end
      end
    end
  end
end
