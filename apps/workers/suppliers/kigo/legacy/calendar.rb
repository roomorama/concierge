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
      return unless can_proceed?

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
      @properties ||= PropertyRepository.from_host(host).identified_by(identifiers)
    end

    def importer
      @importer ||= Kigo::Importer.new(credentials, request_handler)
    end

    def request_handler
      @request_handler ||= Kigo::LegacyRequest.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(Kigo::Legacy::SUPPLIER_NAME)
    end

    def can_proceed?
      # in case there are no properties to be updated (no +identifiers+ given, in
      # case there are no changes since the last run of the synchronisation process,
      # for instance), then the +properties+ array will be empty. In such cases,
      # the process can continue, but nothing will be updated.
      return true if properties.empty?

      ids = properties.collect { |p| p.identifier }
      result = Kigo::HostCheck.new(ids, request_handler).active?
      result.success? && result.value
    end
  end
end
