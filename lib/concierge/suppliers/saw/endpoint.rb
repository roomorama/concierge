module SAW
  class Endpoint
    ENDPOINTS = {
      countries: "xml/country.aspx",
      propertydetail: "xml/propertydetail.aspx",
      images: "xml/propertydetail.aspx",
      propertyrates: "xml/propertyrates.aspx",
      propertysearch: "xml/propertysearch.aspx",
      propertylist: "xml/propertylist.aspx",
      propertybooking: "xml/propertybooking.aspx"
    }

    def self.endpoint_for(api_method)
     ENDPOINTS[api_method]
    end
  end
end
