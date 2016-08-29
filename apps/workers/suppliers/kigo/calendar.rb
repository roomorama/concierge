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
        id = property.identifier
        synchronisation.start(id) do
          pricing = importer.fetch_prices(id)
          next pricing unless pricing.success?

          availabilities = importer.fetch_availabilities(id)
          next availabilities unless availabilities.success?

          calendar = Kigo::Calendar.new(property)
          calendar.perform(pricing.value, availabilities.value)
        end
      end

      synchronisation.finish!
    end

    private

    def properties
      properties = PropertyRepository.from_host(host)
      properties.identified_by(identifiers) if identifiers.any?
      properties
    end

    def importer
      @importer ||= Kigo::Importer.new(credentials, request_handler)
    end

    def request_handler
      Kigo::Request.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(supplier_name)
    end

    def supplier_name
      Kigo::Client::SUPPLIER_NAME
    end
  end
end

# listen supplier worker
Concierge::Announcer.on("availabilities.Kigo") do |host|
  Workers::Suppliers::Kigo::Calendar.new(host).perform
end
