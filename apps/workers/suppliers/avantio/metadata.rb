module Workers::Suppliers::Avantio
  # +Workers::Suppliers::Avantio::Metadata+
  #
  # Performs properties synchronisation with supplier.
  # This is aggregated worker so it performs sync for all the hosts.
  #
  # Avantio provides all information required for sync by files and
  # updates them with different frequency. This frequency should affect the worker
  # schedule.
  # Update frequency for appropriate files:
  #  - accommodations: twice a week
  #  - descriptions: twice a week
  #  - rates: every day
  #  - occupational rules: several times a week
  #  - availabilities: every day or even more often
  class Metadata
    # Count of days
    PERIOD_SYNC = 365

    attr_reader :supplier

    def initialize(supplier)
      @supplier = supplier
    end

    def perform
      properties = new_context { fetch_properties }
      return unless properties.success?
      properties = properties.value

      descriptions = fetch_descriptions
      return unless descriptions.success?
      descriptions = descriptions.value

      occupational_rules = fetch_occupational_rules
      return unless occupational_rules.success?
      occupational_rules = occupational_rules.value

      rates = fetch_rates
      return unless rates.success?
      rates = rates.value

      availabilities = fetch_availabilities
      return unless availabilities.success?
      availabilities = availabilities.value

      hosts.each do |host|
        perform_for_host(host, properties.fetch(host.identifier, []), descriptions,
                         occupational_rules, rates, availabilities)
      end
    end

    private

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

    def perform_for_host(host, properties, descriptions, occupational_rules, rates, availabilities)
      synchronisation = Workers::PropertySynchronisation.new(host)
      properties.each do |property|
        property_id = property.property_id

        synchronisation.start(property_id) do
          unless validator(property).valid?
            next skip_property(synchronisation, property_id, 'Invalid property')
          end

          rate = rates[property_id]
          unless rate
            next skip_property(synchronisation, property_id, 'Rate not found')
          end

          description = descriptions[property_id]
          unless description && description_validator(description).valid?
            next skip_property(synchronisation, property_id, 'Description not found or invalid')
          end

          occupational_rule = occupational_rules[property.occupational_rule_id]
          unless occupational_rule
            next skip_property(synchronisation, property_id, 'Occupational rule not found')
          end

          # Availability is not used for property building, but used for calendar building.
          # So just to be sure that property has availability.
          unless availabilities[property_id]
            next skip_property(synchronisation, property_id, 'Availabilities not found')
          end

          Result.new(mapper(property, description, occupational_rule, rate).build)
        end
      end
      finish_sync(synchronisation)
    end

    # The method extracted only for specs because RSpec doesn't allow expect the result for
    # several instances of the same class.
    def finish_sync(sync)
      sync.finish!
    end

    # The method extracted only for specs because RSpec doesn't allow expect the result for
    # several instances of the same class.
    def skip_property(sync, property_id, message)
      sync.skip_property(property_id, message)
    end

    def failed_sync(message)
      yield.tap do |result|
        announce_error(message, result) unless result.success?
      end
    end

    def fetch_occupational_rules
      message = 'Failed to perform the `#fetch_occupational_rules` operation'
      failed_sync(message) { importer.fetch_occupational_rules }
    end

    def fetch_properties
      message = 'Failed to perform the `#fetch_properties` operation'
      failed_sync(message) { importer.fetch_properties }
    end

    def fetch_descriptions
      message = 'Failed to perform the `#fetch_descriptions` operation'
      failed_sync(message) { importer.fetch_descriptions }
    end

    def fetch_rates
      message = 'Failed to perform the `#fetch_rates` operation'
      failed_sync(message) { importer.fetch_rates }
    end

    def fetch_availabilities
      message = 'Failed to perform the `#fetch_availabilities` operation'
      failed_sync(message) { importer.fetch_availabilities }
    end

    def mapper(property, description, occupational_rule, rate)
      ::Avantio::Mappers::RoomoramaProperty.new(property, description, occupational_rule, rate, PERIOD_SYNC)
    end

    def importer
      @importer ||= ::Avantio::Importer.new(Concierge::Credentials.for(::Avantio::Client::SUPPLIER_NAME))
    end

    def validator(property)
      Avantio::Validators::PropertyValidator.new(property)
    end

    def description_validator(description)
      Avantio::Validators::DescriptionValidator.new(description)
    end

    def hosts
      HostRepository.from_supplier(supplier)
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
Concierge::Announcer.on('metadata.Avantio') do |supplier, args|
  Workers::Suppliers::Avantio::Metadata.new(supplier).perform
  Result.new({})
end
