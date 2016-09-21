module SAW
  # +SAW::PayloadBuilder+
  #
  # This class builds XML payloads for all SAW endpoints.
  class PayloadBuilder

    # Need to fetch all available accomodations
    ALL_ACCOMODATIONS_TYPE_CODE = -1

    # Fetch only best available rates (ignore non-refundable rates)
    FLAG_RATEPLAN = "N"

    def initialize(credentials)
      @credentials = credentials
    end

    def build_compute_pricing(property_id:,
                              unit_id:,
                              check_in:,
                              check_out:,
                              num_guests:)
      %{
        <request>
          #{build_username_and_password}
          <propertyid>#{property_id}</propertyid>
          <check_in>#{check_in}</check_in>
          <check_out>#{check_out}</check_out>
          <flag_rateplan>#{FLAG_RATEPLAN}</flag_rateplan>

          <apartments>
            <accommodation_type>
              <accommodation_typeid>#{ALL_ACCOMODATIONS_TYPE_CODE}</accommodation_typeid>
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
            <first_name>#{user.fetch(:first_name)}</first_name>
            <last_name>#{user.fetch(:last_name)}</last_name>
            <phone>111-222-333</phone>
            <email>#{user.fetch(:email)}</email>
          </customer_detail>
          <apartments>
            <property_accommodation>
              <property_accommodationid>#{unit_id}</property_accommodationid>
              <number_of_guests>#{num_guests}</number_of_guests>
              <guest_first_name>#{user.fetch(:first_name)}</guest_first_name>
              <guest_last_name>#{user.fetch(:last_name)}</guest_last_name>
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

    def build_property_rate_request(ids:, check_in:, check_out:, guests:)
      %{
        <request>
          #{build_username_and_password}
          <propertyid>#{ids}</propertyid>
          <check_in>#{check_in}</check_in>
          <check_out>#{check_out}</check_out>
          <flag_rateplan>#{FLAG_RATEPLAN}</flag_rateplan>

          <apartments>
            <accommodation_type>
              <accommodation_typeid>#{ALL_ACCOMODATIONS_TYPE_CODE}</accommodation_typeid>
              <number_of_guests>#{guests}</number_of_guests>
            </accommodation_type>
          </apartments>
        </request>
      }
    end

    def build_cancel_request(reference_number)
      %{
        <request>
          #{build_username_and_password}
          <booking_ref_number>#{reference_number}</booking_ref_number>
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

    def build_property_container(property_id)
      %{
        <properties>
          <propertyid>#{property_id}</propertyid>
        </properties>
      }
    end
  end
end
