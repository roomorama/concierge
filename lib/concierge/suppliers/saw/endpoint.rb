module SAW
  class Endpoint
    ENDPOINTS = {
      countries:        "xml/country.aspx",
      property_detail:  "xml/propertydetail.aspx",
      images:           "xml/propertydetail.aspx",
      property_rates:   "xml/propertyrates.aspx",
      property_search:  "xml/propertysearch.aspx",
      property_list:    "xml/propertylist.aspx",
      property_booking: "xml/propertybooking.aspx"
    }

    def self.endpoint_for(api_method)
      ENDPOINTS.fetch(api_method)
    end
  end
end
