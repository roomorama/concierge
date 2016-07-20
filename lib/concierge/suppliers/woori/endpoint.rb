module Woori
  # +Woori::Endpoint+
  #
  # This class provides mapping between internal endpoint names and 
  # corresponding Woori API urls.
  class Endpoint
    ENDPOINTS = {
      properties: "properties"
    }

    # Returns a URL part for a given endpoint by its system name
    # Raises exception in case if endpoint could not be found
    def self.endpoint_for(api_method)
      ENDPOINTS.fetch(api_method)
    end
  end
end
