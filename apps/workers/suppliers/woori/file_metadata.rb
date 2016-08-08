module Workers::Suppliers::Woori
  # +Workers::Suppliers::Woori::FileImporter+
  #
  # Performs synchronisation with supplier using files provided by supplier.
  #
  # There is no event listener for this worker, synchronisation should be 
  # started manually.
  class FileMetadata
    class UnitRatesFetchError < StandardError; end

    attr_reader :synchronisation, :host
    
    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      puts "Parsing properties..."
      all_properties.each do |property|
        synchronisation.start(property.identifier) do
          puts "Starting sync for #{property.identifier}"
          Concierge.context.disable!

          units = all_property_units(property.identifier)
          puts "  Found #{units.size} units for #{property.identifier}"
          units.each do |unit|
            puts "    Fetching rates for #{unit.identifier}..."
            rates_result = fetch_unit_rates(unit)

            if rates_result.success?
              rates = rates_result.value

              unit.nightly_rate = rates.nightly_rate
              unit.weekly_rate  = rates.weekly_rate
              unit.monthly_rate = rates.monthly_rate
            else
              announce_property_unit_rates_fetch_error(unit, rates_result)
              rates_result
            end

            property.add_unit(unit)
          end

          property.nightly_rate = units.map(&:nightly_rate).max
          property.weekly_rate = units.map(&:weekly_rate).max
          property.monthly_rate = units.map(&:monthly_rate).max

          property.type = 'apartment'
          Result.new(property)
        end
      end

      synchronisation.finish!
    end

    private

    def file_importer
      @file_importer ||= ::Woori::FileImporter.new
    end

    def api_importer
      @api_importer ||= ::Woori::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(::Woori::Client::SUPPLIER_NAME)
    end

    def all_properties
      @all_properties ||= file_importer.fetch_all_properties
    end

    def all_property_units(property_id)
      @all_units ||= file_importer.fetch_all_property_units(property_id)
    end

    def fetch_unit_rates(unit)
      retries ||= 3
      result = api_importer.fetch_unit_rates(unit.identifier)

      if result.success?
        result
      else
        raise UnitRatesFetchError
      end
    rescue UnitRatesFetchError
      if (retries -= 1) > 0
        puts "Failed to fetch rates for #{unit.identifier}. Retrying..."
        retry
      else
        puts "No more retries for #{unit.identifier}"
        result
      end
    end

    def announce_property_unit_rates_fetch_error(unit, result)
      message = "Failed to perform the `#fetch_unit_rates` operation for unit id=#{unit.identifier}"

      announce_error(message, result)
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
