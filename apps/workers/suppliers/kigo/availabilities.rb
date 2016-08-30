module Workers::Suppliers::Kigo
  # +Workers::Suppliers::Kigo::Availabilities+
  #
  # this class responsible for handling differences identifiers
  # and calling process +Workers::Suppliers::Kigo::Calendar+ only for hosts
  # which has any changes
  class Availabilities

    attr_reader :supplier, :prices_diff_id, :availabilities_diff_id

    def initialize(supplier, prices_diff_id:, availabilities_diff_id:)
      @supplier               = supplier
      @prices_diff_id         = prices_diff_id
      @availabilities_diff_id = availabilities_diff_id
    end

    def perform
      prices_diff = importer.fetch_prices_diff(prices_diff_id)
      unless prices_diff.success?
        announce_error('Failed to perform `#fetch_prices_diff` operation', prices_diff)
        return
      end

      availabilities_ids = importer.fetch_availabilities_diff(availabilities_diff_id)
      unless availabilities_ids.success?
        announce_error('Failed to perform `#fetch_availabilities_diff` operation', availabilities_ids)
        return
      end

      identifiers = prices_diff.value['PROP_ID'] | availabilities_ids.value['PROP_ID']

      hosts.each { |host| update_calendar(host, identifiers) }

      Result.new({
                   prices_diff_id:         prices_diff.value['DIFF_ID'],
                   availabilities_diff_id: availabilities_ids.value['DIFF_ID']
                 })
    end

    private

    def importer
      @importer ||= Kigo::Importer.new(credentials, request_handler)
    end

    def request_handler
      Kigo::Request.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(supplier.name)
    end

    def hosts
      HostRepository.from_supplier(supplier)
    end

    def update_calendar(host, identifiers)
      Workers::Suppliers::Kigo::Calendar.new(host, identifiers).perform
    end

    def announce_error(message, result)
      message = {
        label:     'Synchronisation Failure',
        message:   message,
        backtrace: caller
      }
      context = Concierge::Context::Message.new(message)
      Concierge.context.augment(context)

      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   'sync',
        supplier:    supplier.name,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

Concierge::Announcer.on("availabilities.Kigo") do |supplier, args|
  Workers::Suppliers::Kigo::Availabilities.new(supplier, args[:prices_diff_id], args[:availabilities_diff_id]).perform
end