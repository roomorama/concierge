module SAW
  # +SAW::PayloadBuilder+
  #
  # This class builds XML payloads for all SAW endpoints.
  class PayloadBuilder
    
    # Need to fetch all available accomodations
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

    def build_booking_request(property_id:,
                              unit_id:,
                              currency_code:,
                              total:,
                              check_in:,
                              check_out:,
                              num_guests:,
                              user:)
      %{
        <request>
          #{build_username_and_password}
          <propertyid>#{property_id}</propertyid>
          <currency_code>#{currency_code}</currency_code>
          <check_in>#{check_in}</check_in>
          <check_out>#{check_out}</check_out>
          <customer_detail>
            <first_name>#{user.fetch(:firstname)}</first_name>
            <last_name>#{user.fetch(:lastname)}</last_name>
            <phone>111-222-333</phone>
            <email>#{user.fetch(:email)}</email>
          </customer_detail>
          <apartments>
            <property_accommodation>
              <property_accommodationid>#{unit_id}</property_accommodationid>
              <number_of_guests>#{num_guests}</number_of_guests>
              <guest_first_name>#{user.fetch(:firstname)}</guest_first_name>
              <guest_last_name>#{user.fetch(:lastname)}</guest_last_name>
            </property_accommodation>
          </apartments>
          <flag_paylater>Y</flag_paylater>
        </request>
      }
    end

    def build_countries_request
      %{
        <request>
          #{build_username_and_password}
        </request>
      }
    end

    def propertysearch_request(country:, property_id: nil)
      %{
        <request>
          #{build_username_and_password}
          <countryid>#{country}</countryid>
          <number_of_guests>-1</number_of_guests>
          <flag_free_sale>Y</flag_free_sale>
          #{property_id ? build_property_container(property_id) : nil }
        </request>
      }
    end
    
    def propertydetail_request(property_id)
      %{
        <request>
          #{build_username_and_password}
          <propertyid>#{property_id}</propertyid>
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

    def build_property_container(property_id)
      %{
        <properties>
          <propertyid>#{property_id}</propertyid>
        </properties> 
      }
    end
  end
end
