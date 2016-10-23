module JTB
  class Cancel
    ENDPOINT       = 'GA_Cancel_v2013'
    OPERATION_NAME = :gby012

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials.api
    end

    def cancel(params)
      reference_number = params[:reference_number]

      reservation = find_reservation(reference_number)
      return reservation_not_found(reference_number) unless reservation

      message = builder.cancel(reservation)
      result = remote_call(message)

      return result unless result.success?

      result = response_parser.parse_cancel(result.value)
      return result unless result.success?

      Result.new(reference_number)
    end

    private

    def response_parser
      @response_parser ||= ResponseParser.new
    end

    def reservation_not_found(reference_number)
      Result.error(:reservation_not_found, "Reservation with reference number #{reference_number} not found")
    end

    def find_reservation(reference_number)
      ReservationRepository.by_supplier(JTB::Client::SUPPLIER_NAME)
        .by_reference_number(reference_number).first
    end

    def builder
      @builder ||= XMLBuilder.new(credentials)
    end

    def caller
      @caller ||= Concierge::SOAPClient.new(options)
    end

    def options
      endpoint = [credentials['url'], ENDPOINT].join('/')
      {
        wsdl:                 endpoint + '?wsdl',
        env_namespace:        :soapenv,
        namespace_identifier: 'jtb',
        endpoint:             endpoint
      }
    end

    def remote_call(message)
      caller.call(OPERATION_NAME, message: message.to_xml,
                  attributes: { PassiveIndicator: credentials['test'] })
    end
  end
end