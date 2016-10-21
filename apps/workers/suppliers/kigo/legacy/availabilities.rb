module Workers::Suppliers::Kigo::Legacy
  # +Workers::Suppliers::Kigo::Legacy::Availabilities+
  #
  # this class responsible for handling differences identifiers
  # and calling process +Workers::Suppliers::Kigo::Legacy::Calendar+ only for hosts
  # which has any changes
  class Availabilities

    attr_reader :supplier, :prices_diff_id, :reservations_diff_id

    def initialize(supplier, args = {})
      @supplier             = supplier
      @prices_diff_id       = args[:prices_diff_id]
      @reservations_diff_id = args[:reservations_diff_id]
    end

    def perform
      prices_diff = importer.fetch_prices_diff(prices_diff_id)
      unless prices_diff.success?
        announce_error('Failed to perform `#fetch_prices_diff` operation', prices_diff)
        return initial_args_result
      end

      reservations = importer.fetch_reservations_diff(reservations_diff_id)
      unless reservations.success?
        announce_error('Failed to perform `#fetch_reservations_diff` operation', reservations)
        return initial_args_result
      end

      reservations_ids = reservations.value['RES_LIST'].map { |reservation| reservation['PROP_ID'] }
      identifiers      = prices_diff.value['PROP_ID'] | reservations_ids

      hosts.each { |host| update_calendar(host, identifiers) }

      Result.new({
                   prices_diff_id:       prices_diff.value['DIFF_ID'],
                   reservations_diff_id: reservations.value['DIFF_ID']
                 })
    end

    private

    def importer
      @importer ||= Kigo::Importer.new(credentials, request_handler)
    end

    def request_handler
      # huge timeout because the first call takes around 3 minutes
      Kigo::LegacyRequest.new(credentials, timeout: 200)
    end

    def credentials
      Concierge::Credentials.for(Kigo::Legacy::SUPPLIER_NAME)
    end

    def hosts
      HostRepository.from_supplier(supplier)
    end

    def update_calendar(host, identifiers)
      Workers::Suppliers::Kigo::Legacy::Calendar.new(host, identifiers).perform
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
        description: result.error.data,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    def initial_args_result
      Result.new({
                   prices_diff_id:       prices_diff_id,
                   reservations_diff_id: reservations_diff_id
                 })
    end
  end
end

Concierge::Announcer.on("availabilities.KigoLegacy") do |supplier, args|
  Workers::Suppliers::Kigo::Legacy::Availabilities.new(supplier, args).perform
end
