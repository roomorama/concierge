# +Workers::Suppliers::KigoCalendar+
#
# Performs updating properties calendar
class Workers::Suppliers::KigoCalendar

  attr_reader :synchronisation, :host

  def initialize(host)
    @host            = host
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

        reservations = importer.fetch_reservations(id)
        next reservations unless reservations.success?

        calendar = Kigo::Calendar.new(property)
        calendar.perform(pricing, availabilities, reservations)
      end
    end

    synchronisation.finish!
  end

  private

  def properties
    @properties ||= PropertyRepository.from_host(host).all
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
