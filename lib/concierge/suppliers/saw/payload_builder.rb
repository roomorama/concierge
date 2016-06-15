module SAW
  class PayloadBuilder
    
    DEFAULT_ACCOMODATION_TYPE = -1
    
    def initialize(credentials)
      @credentials = credentials
    end

    def build_compute_pricing(property_id:,
                              unit_id:,
                              currency_code:,
                              check_in:,
                              check_out:,
                              num_guests:)
      %{
        <request>
          #{build_username_and_password}
          <currency_code>#{currency_code}</currency_code>
          <propertyid>#{property_id}</propertyid>
          <check_in>#{check_in}</check_in>
          <check_out>#{check_out}</check_out>

          <apartments>
            <accommodation_type>
              #{selected_or_default_accommodation_type(unit_id)}
              <number_of_guests>#{num_guests}</number_of_guests>
            </accommodation_type>
          </apartments>
        </request>
      }
    end
    
    private
    def build_username_and_password
      %{
        <username>#{@credentials.username}</username> 
        <password>#{@credentials.password}</password> 
      }
    end

    def selected_or_default_accommodation_type(unit_id)
      accommodation_type_id = unit_id ? unit_id : DEFAULT_ACCOMODATION_TYPE

      %{
        <accommodation_typeid>#{accommodation_type_id}</accommodation_typeid>
      }
    end
  end
end
