module Workers::Suppliers::THH
  # +Workers::Suppliers::THH::Availabilities+
  #
  # Performs properties availabilities synchronisation with supplier
  class Availabilities
    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      identifiers = all_identifiers

      identifiers.each do |property_id|
        synchronisation.start(property_id) do
          result = fetch_property(property_id)
          next result unless result.success?
          property = result.value

          roomorama_calendar = mapper.build(property)
          Result.new(roomorama_calendar)
        end
      end
      synchronisation.finish!
    end

    private

    def report_error(message)
      yield.tap do |result|
        augment_context_error(message) unless result.success?
      end
    end

    def fetch_property(property_id)
      report_error("Failed to fetch details for property `#{property_id}`") do
        importer.fetch_property(property_id)
      end
    end

    def all_identifiers
      PropertyRepository.from_host(host).only(:identifier).map(&:identifier)
    end

    def mapper
      @mapper ||= ::THH::Mappers::RoomoramaCalendar.new
    end

    def importer
      @importer ||= ::THH::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(THH::Client::SUPPLIER_NAME)
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
Concierge::Announcer.on('availabilities.THH') do |host, args|
  Workers::Suppliers::THH::Availabilities.new(host).perform
  Result.new({})
end
