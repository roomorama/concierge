# +Workers::Suppliers::KigoCalendar+
#
# Performs updating properties calendar
class Workers::Suppliers::KigoCalendar

  attr_reader :synchronisation, :host, :identifiers

  def initialize(host, identifiers = [])
    @host            = host
    @identifiers     = identifiers
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
    Kigo::Request.new(credentials, timeout: 40)
  end

  def credentials
    Concierge::Credentials.for(supplier_name)
  end

  def supplier_name
    Kigo::Client::SUPPLIER_NAME
  end
end

# listen supplier worker
Concierge::Announcer.on("availabilities.Kigo") do |host|
  Workers::Suppliers::KigoCalendar.new(host).perform
end
