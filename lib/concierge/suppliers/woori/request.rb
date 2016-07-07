require 'uri'

module Woori

  # +Woori::Request+
  #
  # This class is responsible for building the request payload to be sent to Woori's
  # API, for different calls.
  #
  # Usage (for the example of retrieving one property)
  #
  #   request = Woori::Request.new(credentials)
  #   request.get_property(property_identifier, params_hash)
  #   # => RESULT - To be completed

  module Request
    END_POINTS = YAML::load(File.open(File.join('lib', 'roomallo_api', 'end_points.yml')))
    BASE_URI = "https://api.ytlabs.co.kr/stage/v1/"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    ## Example usage based on get_property (i.e. get one property with a property identifier)
    ## Example usage: get_property("w_w0307360")
    ## Example usage: get_property("w_w0307360", {:=i81n => "en-US"})
    def get_property(property_identifier, params=nil)
      if params
        ["#{build_url(__method__.to_s, property_identifier)}", "?", transform_params(params)].join
      else
        "#{build_url(__method__.to_s, property_identifier)}"
      end
    end

    private

    # Returns a String with the base URL of the API.
    def base_uri
      BASE_URI
    end

    ## Transforms a Ruby hash {:a => 2, :b => 2} to "a=2&b=2"
    def transform_params(params)
      URI.encode_www_form(params)
    end

    #Private method to build endpoint URL. An action maps to an endpoint address.
    # i.e. get_property to /properties.
    # An identifier (property_hash) is required rather than an id in this case.
    # To build "properties/w_w0307360" as the URL.
    def build_url(action, identifier = nil)
      end_point = END_POINTS[action]

      if identifier
        url = "#{base_uri}/#{end_point}/#{identifier}"
      else
        url = "#{base_uri}/#{end_point}"
      end
      url
    end

  end

end
