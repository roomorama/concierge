module Workers::Suppliers::Kigo
  # +Workers::Suppliers::Kigo::Calendars+
  #
  # this class responsible for handling differences identifiers
  # and calling process +Workers::Suppliers::Kigo::Calendar+ only for hosts
  # which has any changes
  class Calendars

    PRICES_DIFF_KEY         = 'prices_diff_id'
    AVAILABILITIES_DIFF_KEY = 'availabilities_diff_id'

    def initialize(name)
      @supplier = SupplierRepository.named(name)
    end

    def perform
      prices_ids = fetch_prices_ids
      return unless prices_ids.success?

      availabilities_ids = fetch_availabilities_ids
      return unless availabilities_ids.success?

      hosts.each do |host|
        Workers::Suppliers::Kigo::Calendar.new(host, identifiers).perform
      end
    end

    private

    def importer
      @importer ||= Kigo::Importer.new(credentials, request_handler)
    end

    def credentials
      Concierge::Credentials.for(supplier_name)
    end

    def supplier_name
      Kigo::Client::SUPPLIER_NAME
    end

    def prices_diff_id
      cache.read(PRICES_DIFF_KEY)
    end

    def fetch_prices_ids
      result = importer.fetch_prices_diff(prices_diff_id)

      return result unless result.success?

      refresh_cache(PRICES_DIFF_KEY, result.value['DIFF_ID'])
      result.value['PROP_ID']
    end

    def availabilities_diff_id
      cache.read(AVAILABILITIES_DIFF_KEY)
    end

    def fetch_availability_ids
      result = importer.fetch_availabilities_diff(availabilities_diff_id)

      return result unless result.success?

      refresh_cache(AVAILABILITIES_DIFF_KEY, result.value['DIFF_ID'])
      result.value['PROP_ID']
    end

    def refresh_cache(key, value)
      cache.invalidate(key)
      with_cache(key) { value }
    end

    def with_cache(key)
      freshness = 60 * 60 * 3 # 3 hours
      cache.fetch(key, freshness: freshness) { yield }
    end

    def cache
      @_cache ||= Concierge::Cache.new(namespace: 'kigo.diff')
    end
  end
end

# listen supplier worker
Concierge::Announcer.on("availabilities.Kigo") do
  Workers::Suppliers::Kigo::Calendars.new.perform
end
