module Woori
  module Converters
    # +Woori::Converters::CountryCode+
    #
    # This class acts as a facade between country codes converter library and
    # our source code for abstracting library's entities and using only needed 
    # part of the library API.
    #
    # There is also one added step in country code convertion: this class adds
    # a step for *prettyfying* country names because there is some differences 
    # between which names are used in country codes converter library and in 
    # Woori API.
    class CountryCode
      CUSTOM_COUNTRY_CODES = {
        "Korea" => "KR",
        '대한민국' => "KR"
      }

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
        custom_code = CUSTOM_COUNTRY_CODES[name]

        return custom_code if custom_code

        country = IsoCountryCodes.search_by_name(name).first
        (country && country.alpha2).to_s
      end
    end
  end
end
