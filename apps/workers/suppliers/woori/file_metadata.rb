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
      all_properties.each do |property|
        synchronisation.start(property.identifier) do
          # Concierge.context.disable!

          units = all_property_units(property.identifier)
          units.each { |unit| property.add_unit(unit) }

          Result.new(property)
        end
      end

      synchronisation.finish!
    end

    private

    def file_importer
      @file_importer ||= ::Woori::FileImporter.new(credentials)
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
        retry
      else
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
