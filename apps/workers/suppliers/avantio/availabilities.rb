module Workers::Suppliers::Avantio
  # +Workers::Suppliers::Avantio::Availabilities+
  #
  # Performs properties availabilities synchronisation with supplier
  #
  # Avantio provides all information required for sync by files and
  # updates them with different frequency. This frequency should affect the worker
  # schedule.
  # Update frequency for appropriate files:
  #  - rates: every day
  #  - occupational rules: several times a week
  #  - availabilities: every day
  class Availabilities
    # Count of days
    PERIOD_SYNC = 365

    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      identifiers = all_identifiers

      rates = synchronisation.new_context { fetch_rates(host) }
      return unless rates.success?
      rates = rates.value

      availabilities = fetch_availabilities(host)
      return unless availabilities.success?
      availabilities = availabilities.value

      occupational_rules = fetch_occupational_rules(host)
      return unless occupational_rules.success?
      occupational_rules = occupational_rules.value

      identifiers.each do |property_id|

        synchronisation.start(property_id) do

          rate = rates[property_id]
          unless rate
            message = "Rate for property `#{property_id}` nof found"
            augment_context_error(message)
            next Result.error(:rate_not_found)
          end

          availability = availabilities[property_id]
          unless availability
            message = "Availability for property `#{property_id}` nof found"
            augment_context_error(message)
            next Result.error(:availability_not_found)
          end

          rule = occupational_rules[availability.occupational_rule_id]
          unless rule
            message = "Occupational rule for property `#{property_id}` nof found"
            augment_context_error(message)
            next Result.error(:rule_not_found)
          end

          roomorama_calendar = mapper(property_id, rate, availability, rule).build
          Result.new(roomorama_calendar)
        end
      end
      synchronisation.finish!
    end

    private

    def failed_sync(message)
      yield.tap do |result|
        unless result.success?
          announce_error(message, result)
        end
      end
    end

    def fetch_rates(host)
      message = 'Failed to perform the `#fetch_rates` operation'
      failed_sync(message) { importer.fetch_rates(host) }
    end

    def fetch_availabilities(host)
      message = 'Failed to perform the `#fetch_availabilities` operation'
      failed_sync(message) { importer.fetch_availabilities(host) }
    end

    def fetch_occupational_rules(host)
      message = 'Failed to perform the `#fetch_occupational_rules` operation'
      failed_sync(message) { importer.fetch_occupational_rules(host) }
    end

    def all_identifiers
      PropertyRepository.from_host(host).only(:identifier).map(&:identifier)
    end

    def mapper(property_id, rate, availability, rule)
      ::Avantio::Mappers::RoomoramaCalendar.new(property_id, rate, availability, rule, PERIOD_SYNC)
    end

    def importer
      @importer ||= ::Avantio::Importer.new
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
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('availabilities.Avantio') do |host, args|
  Workers::Suppliers::Avantio::Availabilities.new(host).perform
  Result.new({})
end
