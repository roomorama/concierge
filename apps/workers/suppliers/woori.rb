module Workers::Suppliers
  # +Workers::Suppliers::Woori+
  #
  # Performs synchronisation with supplier
  class Woori
    attr_reader :synchronisation, :host
    
    BATCH_SIZE     = 30

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      offset = 0

      puts "last_synced_date=#{last_synced_date}"

      begin
        result = importer.fetch_properties(last_synced_date, BATCH_SIZE, offset)

        if result.success?
          puts "FETCH PROPERTIES. Fetched: #{result.value.size} properties. (limit: #{BATCH_SIZE}, offset: #{offset})"
          properties = result.value
          size_fetched = properties.size
          offset = offset + size_fetched

          properties.each do |property|
            synchronisation.start(property.identifier) do
              Concierge.context.disable!
              puts "  Processing property id=#{property.identifier}..."

              begin
                units_result = importer.fetch_units(property.identifier)

                if units_result.success?
                  puts "    FETCH UNITS: Fetched: #{units_result.value.size} units for property id=#{property.identifier}"
                  units = units_result.value

                  units.each do |unit|
                    puts "      FETCH UNIT RATES: Processing unit id=#{unit.identifier} for property id=#{property.identifier}"
                    begin
                      rates_result = importer.fetch_unit_rates(unit.identifier)

                      if rates_result.success?
                        rates = rates_result.value

                        puts "      FETCH UNIT RATES: Success for #{unit.identifier}: #{rates.nightly_rate} / #{rates.weekly_rate} / #{rates.monthly_rate}"

                        unit.nightly_rate = rates.nightly_rate
                        unit.weekly_rate  = rates.weekly_rate
                        unit.monthly_rate = rates.monthly_rate

                        property.add_unit(unit)
                      else
                        message = "      FETCH UNIT RATES: Failed to perform the `#fetch_unit_rates` operation for unit id=#{unit.identifier}. Retrying..."
                        puts message
                        announce_error(message, units_result)
                        # rates_result
                        raise "error"
                      end
                    rescue
                      retry
                    end
                  end

                  Result.new(property)
                else
                  message = "    FETCH UNITS: Failed to perform the `#fetch_units` operation for property id=#{property.identifier}. Retrying..."
                  puts message
                  announce_error(message, units_result)
                  # units_result
                  raise "error"
                end
              rescue
                retry
              end
            end
          end
        else
          message = "Failed to perform the `#fetch_properties` operation. Parameters: date=#{last_synced_date} limit=#{BATCH_SIZE} offset=#{offset}. Retrying..."
          puts message
          announce_error(message, result)
          next
        end
      end while size_fetched == BATCH_SIZE
      
      synchronisation.finish!
    end

    private

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
  end
end

# Listen supplier worker
Concierge::Announcer.on("metadata.Woori") do |host|
  Workers::Suppliers::Woori.new(host).perform
end
