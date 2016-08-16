module Workers::Suppliers::Ciirus
  # +Workers::Suppliers::Ciirus::Calendar+
  #
  # Performs properties availabilities synchronisation with supplier
  class Calendar
    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      identifiers = all_identifiers

      identifiers.each do |property_id|
        synchronisation.start(property_id) do
          result = fetch_rates(property_id)
          next result unless result.success?
          rates = result.value

          result = fetch_reservations(property_id)
          next result unless result.success?
          reservations = result.value

          roomorama_calendar = mapper.build(property_id, rates, reservations)
          Result.new(roomorama_calendar)
        end
      end
      synchronisation.finish!
    end

    private

    def report_error(message)
      yield.tap do |result|
        unless result.success?
          with_context_enabled { augment_context_error(message) }
        end
      end
    end

    def fetch_rates(property_id)
      report_error("Failed to fetch rates for property `#{property_id}`") do
        importer.fetch_rates(property_id)
      end
    end

    def fetch_reservations(property_id)
      report_error("Failed to fetch reservations for property `#{property_id}`") do
        importer.fetch_reservations(property_id)
      end
    end

    def with_context_enabled
      Concierge.context.enable!
      yield
      Concierge.context.disable!
    end

    def all_identifiers
      PropertyRepository.from_host(host).only(:identifier).map(&:identifier)
    end

    def mapper
      @mapper ||= ::Ciirus::Mappers::RoomoramaCalendar.new
    end

    def importer
      @importer ||= ::Ciirus::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(Ciirus::Client::SUPPLIER_NAME)
    end

    def augment_context_error(message)
      message = {
        label: 'Synchronisation Failure',
        message: message,
        backtrace: caller
      }
      context = Concierge::Context::Message.new(message)
      Concierge.context.augment(context)
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('availabilities.Ciirus') do |host|
  Workers::Suppliers::Ciirus::Calendar.new(host).perform
end
