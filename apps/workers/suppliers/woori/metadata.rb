module Workers::Suppliers::Woori
  # +Workers::Suppliers::Woori+
  #
  # Performs synchronisation with supplier
  class Metadata
    class PropertiesFetchError < StandardError; end
    class UnitsFetchError < StandardError; end
    class UnitRatesFetchError < StandardError; end

    attr_reader :synchronisation, :host
    
    BATCH_SIZE     = 30

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      offset = 0

      begin
        result = fetch_properties(last_synced_date, BATCH_SIZE, offset)

        if result.success?
          properties = result.value
          size_fetched = properties.size

          properties.each do |property|
            synchronisation.start(property.identifier) do
              Concierge.context.disable!

              units_result = fetch_property_units(property)

              if units_result.success?
                units = units_result.value

                units.each do |unit|
                  rates_result = fetch_unit_rates(unit)

                  if rates_result.success?
                    rates = rates_result.value

                    unit.nightly_rate = rates.nightly_rate
                    unit.weekly_rate  = rates.weekly_rate
                    unit.monthly_rate = rates.monthly_rate

                    property.add_unit(unit)
                  else
                    announce_property_unit_rates_fetch_error(unit, result)
                    rates_result
                  end
                end

                Result.new(property)
              else
                announce_property_units_fetch_error(property, result)
                units_result
              end
            end
          end

        else
          announce_properties_fetch_error(result)
          return
        end

        offset = offset + size_fetched
      end while size_fetched == BATCH_SIZE

      synchronisation.finish!
    end

    private

    def fetch_properties(date, batch_size, offset)
      retries ||= 3
      result = importer.fetch_properties(date, batch_size, offset)

      if result.success?
        result
      else
        raise PropertiesFetchError
      end
    rescue PropertiesFetchError
      if (retries -= 1) > 0
        retry
      else
        result
      end
    end

    def fetch_property_units(property)
      retries ||= 3
      result = importer.fetch_units(property.identifier)

      if result.success?
        result
      else
        raise UnitsFetchError
      end
    rescue UnitsFetchError
      if (retries -= 1) > 0
        retry
      else
        result
      end
    end

    def fetch_unit_rates(unit)
      retries ||= 3
      result = importer.fetch_unit_rates(unit.identifier)

      if result.success?
        result
      else
        raise UnitRatesFetchError
      end
    rescue UnitRatesFetchError
      if (retries -= 1) > 0
        retry
      else
        result
      end
    end

    def importer
      @importer ||= ::Woori::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(::Woori::Client::SUPPLIER_NAME)
    end

    # Returns the last successful date of a synchronisation
    # Returns default sync date if there has never been a successful sync yet
    def last_synced_date
      most_recent = SyncProcessRepository.recent_successful_sync_for_host(host).first

      if most_recent
        most_recent&.started_at.strftime("%Y-%m-%d")
      else
        init_sync_date
      end
    end

    def init_sync_date
      (Time.now - 7 * 24 * 60 * 60).strftime("%Y-%m-%d")
    end

    def announce_error(message, result)
      message = {
        label: 'Synchronisation Failure',
        message: message,
        backtrace: caller
      }
      context = Concierge::Context::Message.new(message)
      Concierge.context.augment(context)

      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   'sync',
        supplier:    ::Woori::Client::SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    def announce_properties_fetch_error(result)
      message = "Failed to perform the `#fetch_properties` operation"
      announce_error(message, result)
    end

    def announce_property_units_fetch_error(property, result)
      message = "Failed to perform the `#fetch_units` operation for property id=#{property.identifier}"
      announce_error(message, result)
    end

    def announce_property_unit_rates_fetch_error(unit, result)
      message = "Failed to perform the `#fetch_unit_rates` operation for unit id=#{unit.identifier}"

      announce_error(message, result)
    end
  end
end

# Listen supplier worker
Concierge::Announcer.on("metadata.Woori") do |host|
  Workers::Suppliers::Woori.new(host).perform
end
