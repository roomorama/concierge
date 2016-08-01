module SAW
  # +SAW::Endpoint+
  #
  # This class provides mapping between internal endpoint names and
  # corresponding SAW API urls.
  class Endpoint
    ENDPOINTS = {
      countries:        "xml/country.aspx",
      property_detail:  "xml/propertydetail.aspx",
      images:           "xml/propertydetail.aspx",
      property_rates:   "xml/propertyrates.aspx",
      property_search:  "xml/propertysearch.aspx",
      property_list:    "xml/propertylist.aspx",
      property_booking: "xml/propertybooking.aspx",
      cancellation:     "xml/bookingcancellation.aspx"
    }

    # Returns a URL part for a given endpoint by its system name
    # Raises exception in case if endpoint could not be found
    def self.endpoint_for(api_method)
      ENDPOINTS.fetch(api_method)
    end
  end
end
