module Workers::Suppliers::Kigo
  # +Workers::Suppliers::Kigo::Calendar+
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

          availabilities = importer.fetch_availabilities(id)
          next availabilities unless availabilities.success?

          calendar = Kigo::Calendar.new(property)
          calendar.perform(pricing.value, availabilities: availabilities.value['AVAILABILITY'])
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
      Kigo::Request.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(Kigo::Client::SUPPLIER_NAME)
    end
  end
end
