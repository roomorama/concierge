module Workers::Suppliers::Avantio
  # +Workers::Suppliers::Avantio::Availabilities+
  #
  # Performs properties availabilities synchronisation with supplier
  # This is aggregated worker so it performs sync for all the hosts.

  # Avantio provides all information required for sync by files and
  # updates them with different frequency. This frequency should affect the worker
  # schedule.
  # Update frequency for appropriate files:
  #  - rates: every day
  #  - occupational rules: several times a week
  #  - availabilities: every day or even more often
  class Availabilities
    # Count of days
    PERIOD_SYNC = 365

    attr_reader :supplier

    def initialize(supplier)
      @supplier = supplier
    end

    def perform

      rates = new_context { fetch_rates }
      return unless rates.success?
      rates = rates.value

      availabilities = fetch_availabilities
      return unless availabilities.success?
      availabilities = availabilities.value

      occupational_rules = fetch_occupational_rules
      return unless occupational_rules.success?
      occupational_rules = occupational_rules.value

      hosts.each do |host|
        perform_for_host(host, rates, availabilities, occupational_rules)
      end
    end

    private

    # The method extracted only for specs because RSpec doesn't allow expect the result for
    # several instances of the same class.
    def finish_sync(sync)
      sync.finish!
    end

    def perform_for_host(host, rates, availabilities, occupational_rules)
      identifiers = all_identifiers(host)
      synchronisation = Workers::CalendarSynchronisation.new(host)

      identifiers.each do |property_id|

        synchronisation.start(property_id) do

          rate = rates[property_id]
          unless rate
            message = "Rate for property `#{property_id}` not found"
            augment_context_error(message)
            next Result.error(:rate_not_found, message)
          end

          availability = availabilities[property_id]
          unless availability
            message = "Availability for property `#{property_id}` not found"
            augment_context_error(message)
            next Result.error(:availability_not_found, message)
          end

          rule = occupational_rules[availability.occupational_rule_id]
          unless rule
            message = "Occupational rule for property `#{property_id}` not found"
            augment_context_error(message)
            next Result.error(:rule_not_found, message)
          end

          roomorama_calendar = mapper(property_id, rate, availability, rule).build
          Result.new(roomorama_calendar)
        end
      end
      finish_sync(synchronisation)
    end

    def new_context
      Concierge.context = Concierge::Context.new(type: "batch")

      message = Concierge::Context::Message.new(
        label:     'Aggregated Sync',
        message:   "Started aggregated metadata sync for `#{supplier}`",
        backtrace: caller
      )

      Concierge.context.augment(message)
      yield
    end

    def failed_sync(message)
      yield.tap do |result|
        unless result.success?
          announce_error(message, result)
        end
      end
    end

    def fetch_rates
      message = 'Failed to perform the `#fetch_rates` operation'
      failed_sync(message) { importer.fetch_rates }
    end

    def fetch_availabilities
      message = 'Failed to perform the `#fetch_availabilities` operation'
      failed_sync(message) { importer.fetch_availabilities }
    end

    def fetch_occupational_rules
      message = 'Failed to perform the `#fetch_occupational_rules` operation'
      failed_sync(message) { importer.fetch_occupational_rules }
    end

    def all_identifiers(host)
      PropertyRepository.from_host(host).only(:identifier).map(&:identifier)
    end

    def mapper(property_id, rate, availability, rule)
      ::Avantio::Mappers::RoomoramaCalendar.new(property_id, rate, availability, rule, PERIOD_SYNC)
    end

    def hosts
      HostRepository.from_supplier(supplier)
    end

    def importer
      @importer ||= ::Avantio::Importer.new(Concierge::Credentials.for(::Avantio::Client::SUPPLIER_NAME))
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
        supplier:    Avantio::Client::SUPPLIER_NAME,
        code:        result.error.code,
        description: result.error.data,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('availabilities.Avantio') do |supplier, args|
  Workers::Suppliers::Avantio::Availabilities.new(supplier).perform
  Result.new({})
end
