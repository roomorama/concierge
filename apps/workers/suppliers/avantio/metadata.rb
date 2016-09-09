module Workers::Suppliers::Avantio
  # +Workers::Suppliers::Avantio::Metadata+
  #
  # Performs properties synchronisation with supplier
  #
  # Avantio provides all information required for sync by files and
  # updates them with different frequency. This frequency should affect the worker
  # schedule.
  # Update frequency for appropriate files:
  #  - accommodations: twice a week
  #  - descriptions: twice a week
  #  - rates: every day
  #  - occupational rules: several times a week
  class Metadata
    # Count of days
    PERIOD_SYNC = 365

    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      properties = synchronisation.new_context do
        fetch_properties(host)
      end
      return unless properties.success?
      properties = properties.value

      descriptions = fetch_descriptions(host)
      return unless descriptions.success?
      descriptions = descriptions.value

      occupational_rules = fetch_occupational_rules(host)
      return unless occupational_rules.success?
      occupational_rules = occupational_rules.value

      rates = fetch_rates(host)
      return unless rates.success?
      rates = rates.value

      availabilities = fetch_availabilities(host)
      return unless availabilities.success?
      availabilities = availabilities.value

      properties.each do |property|
        unless validator(property).valid?
          synchronisation.skip_property
          next
        end
        property_id = property.property_id
        rate = rates[property_id]
        unless rate
          synchronisation.skip_property
          next
        end
        description = descriptions[property_id]
        unless description && description_validator(description).valid?
          synchronisation.skip_property
          next
        end
        occupational_rule = occupational_rules[property.occupational_rule_id]
        unless occupational_rule
          synchronisation.skip_property
          next
        end
        # Availability is not used for property building, but used for calendar building.
        # So just to be sure that property has availability.
        unless availabilities[property_id]
          synchronisation.skip_property
          next
        end
        synchronisation.start(property_id) do
          Result.new(mapper(property, description, occupational_rule, rate).build)
        end
      end
      synchronisation.finish!
    end

    private

    def failed_sync(message)
      yield.tap do |result|
        unless result.success?
          synchronisation.failed!
          announce_error(message, result)
        end
      end
    end

    def fetch_occupational_rules(host)
      message = 'Failed to perform the `#fetch_occupational_rules` operation'
      failed_sync(message) { importer.fetch_occupational_rules(host) }
    end

    def fetch_properties(host)
      message = 'Failed to perform the `#fetch_properties` operation'
      failed_sync(message) { importer.fetch_properties(host) }
    end

    def fetch_descriptions(host)
      message = 'Failed to perform the `#fetch_descriptions` operation'
      failed_sync(message) { importer.fetch_descriptions(host) }
    end

    def fetch_rates(host)
      message = 'Failed to perform the `#fetch_rates` operation'
      failed_sync(message) { importer.fetch_rates(host) }
    end

    def fetch_availabilities(host)
      message = 'Failed to perform the `#fetch_availabilities` operation'
      failed_sync(message) { importer.fetch_availabilities(host) }
    end

    def mapper(property, description, occupational_rule, rate)
      ::Avantio::Mappers::RoomoramaProperty.new(property, description, occupational_rule, rate, PERIOD_SYNC)
    end

    def importer
      @importer ||= ::Avantio::Importer.new
    end


    def validator(property)
      Avantio::Validators::PropertyValidator.new(property)
    end

    def description_validator(description)
      Avantio::Validators::DescriptionValidator.new(description)
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
Concierge::Announcer.on('metadata.Avantio') do |host, args|
  Workers::Suppliers::Avantio::Metadata.new(host).perform
  Result.new({})
end
