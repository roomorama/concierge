module Workers::Suppliers::RentalsUnited
  # +Workers::Suppliers::RentalsUnited::Calendar+
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
          result = fetch_seasons(property_id)
          next result unless result.success?
          seasons = result.value

          result = fetch_availabilities(property_id)
          next result unless result.success?
          availabilities = result.value

          mapper = ::RentalsUnited::Mappers::Calendar.new(
            property_id,
            seasons,
            availabilities
          )
          Result.new(mapper.build_calendar)
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

    def fetch_seasons(property_id)
      report_error("Failed to fetch seasons for property `#{property_id}`") do
        importer.fetch_seasons(property_id)
      end
    end

    def fetch_availabilities(property_id)
      report_error("Failed to fetch availabilities for property `#{property_id}`") do
        importer.fetch_availabilities(property_id)
      end
    end

    def all_identifiers
      PropertyRepository.from_host(host).only(:identifier).map(&:identifier)
    end

    def importer
      @importer ||= ::RentalsUnited::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(RentalsUnited::Client::SUPPLIER_NAME)
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

Concierge::Announcer.on('availabilities.RentalsUnited') do |host, args|
  Workers::Suppliers::RentalsUnited::Availabilities.new(host).perform
  Result.new({})
end
