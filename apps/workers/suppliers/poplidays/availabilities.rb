module Workers::Suppliers::Poplidays
  # +Workers::Suppliers::Poplidays::Availabilities+
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
          Concierge.context.disable!

          result = fetch_property_details(property_id)
          next result unless result.success?
          details = result.value

          result = fetch_availabilities(property_id)
          next result unless result.success?
          availabilities = result.value

          roomorama_calendar = mapper.build(property_id, details, availabilities)
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

    def fetch_property_details(property_id)
      report_error("Failed to fetch details for property `#{property_id}`") do
        importer.fetch_property_details(property_id)
      end
    end

    def fetch_availabilities(property_id)
      report_error("Failed to fetch availabilities for property `#{property_id}`") do
        importer.fetch_availabilities(property_id)
      end
    end

    def with_context_enabled
      Concierge.context.enable!
      yield
      Concierge.context.disable!
    end

    def mapper
      @mapper ||= ::Poplidays::Mappers::RoomoramaCalendar.new
    end

    def importer
      @importer ||= ::Poplidays::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(Poplidays::Client::SUPPLIER_NAME)
    end

    def all_identifiers
      PropertyRepository.from_host(host).only(:identifier).map(&:identifier)
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

    def announce_error(message, result)
      augment_context_error(message)

      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   'sync',
        supplier:    Poplidays::Client::SUPPLIER_NAME,
        code:        result.error.code,
        description: result.error.data,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('availabilities.Poplidays') do |host, args|
  Workers::Suppliers::Poplidays::Availabilities.new(host).perform
  Result.new({})
end
