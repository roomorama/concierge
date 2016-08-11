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

        calendar = Kigo::Calendar.new(property)
        calendar.perform(pricing.value, availabilities.value)
      end
    end

    synchronisation.finish!
  end

  private

  def properties
    @properties ||= PropertyRepository.from_host(host).identified_by(identifiers).all
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

  def identifiers
    # diff_uid = with_cache('diff_uid') { importer.fetch_prices_diff }
  end

  def with_cache(key)
    freshness = 60 * 60 * 3 # 3 hours
    cache.fetch(key, freshness: freshness, serializer: json_serializer) { yield }
  end

  def json_serializer
    @serializer ||= Concierge::Cache::Serializers::JSON.new
  end

  def cache
    @_cache ||= Concierge::Cache.new(namespace: 'kigo.diff')
  end

end

# listen supplier worker
Concierge::Announcer.on("availabilities.Kigo") do |host|
  Workers::Suppliers::KigoCalendar.new(host).perform
end
