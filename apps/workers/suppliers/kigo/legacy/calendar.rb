module Workers::Suppliers::Kigo::Legacy
  # +Workers::Suppliers::Kigo::Legacy::Calendar+
  #
  # Performs updating properties calendar
  class Calendar

    attr_reader :synchronisation, :host, :identifiers

    def initialize(host, identifiers)
      @host            = host
      @identifiers     = identifiers.map(&:to_s)
      @synchronisation = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      properties.each do |property|
        id = property.identifier.to_i
        synchronisation.start(id) do
          pricing = importer.fetch_prices(id)
          next pricing unless pricing.success?

          reservations = importer.fetch_reservations(id)
          next reservations unless reservations.success?

          calendar = Kigo::Calendar.new(property)
          calendar.perform(pricing.value, reservations: reservations.value)
        end
      end

      synchronisation.finish!
    end

    private

    def properties
      PropertyRepository.from_host(host).identified_by(identifiers)
    end

    def importer
      @importer ||= Kigo::Importer.new(credentials, request_handler)
    end

    def request_handler
      Kigo::LegacyRequest.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(Kigo::Legacy::SUPPLIER_NAME)
    end
  end
end
