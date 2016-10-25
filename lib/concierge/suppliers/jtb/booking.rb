module JTB
  #  +JTB::Booking+
  #
  # This class responsible for creating booking through JTB API.
  # Specific param +RatePlan+ is required to create booking.
  class Booking
    ENDPOINT       = 'GA_HotelRes_v2013'
    OPERATION_NAME = :gby011

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Always returns a +Result+. Successful result contains +String+ value with booking identifier on JTB side.
    # If an error happens in any step in the process of getting a response back from
    # JTB, a generic error message is sent back to the caller, and the failure
    # is logged
    #
    # example:
    #   booking = JTB::Booking.new(credentials)
    #   booking.book(params)
    #
    #   # => #<Result error=nil value='XXXXXXXXXX'>
    def book(params)
      rate_plan = price_handler.best_rate_plan(params)

      return rate_plan unless rate_plan.success?

      u_id = JTB::UnitId.from_roomorama_unit_id(params[:unit_id])

      message = builder.build_booking(params, rate_plan.value, u_id.room_type_code)
      result  = remote_call(message)
      return result unless result.success?

      result = response_parser.parse_booking(result.value)
      return result unless result.success?

      reference_number = ReferenceNumber.from_jtb_ids(result.value, rate_plan.value.rate_plan)

      Result.new(reference_number.reference_number)
    end

    private

    def price_handler
      @price_handler ||= Price.new(credentials)
    end

    def builder
      XMLBuilder.new(credentials.api)
    end

    def remote_call(message)
      client.call(OPERATION_NAME, message: message.to_xml)
    end

    def response_parser
      @response_parser ||= ResponseParser.new
    end

    def client
      @client ||= Concierge::SOAPClient.new(options)
    end

    def options
      endpoint = [credentials.api['url'], ENDPOINT].join('/')
      {
        wsdl:                 endpoint + '?wsdl',
        env_namespace:        :soapenv,
        namespace_identifier: 'jtb',
        endpoint:             endpoint
      }
    end

  end
end
