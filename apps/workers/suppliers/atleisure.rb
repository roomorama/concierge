module Workers::Suppliers
  # +Workers::Suppliers::AtLeisure+
  #
  # Performs synchronisation with supplier
  class AtLeisure
    SUPPLIER_NAME = 'AtLeisure'
    BATCH_SIZE = 100

    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::Synchronisation.new(host)
    end

    def perform
      result = importer.fetch_properties
      if result.success?
        grouped_actual_properties(result.value).each do |properties|
          fetch_data_and_process(properties)
        end
        synchronisation.finish!
      else
        message = "Failed to perform the `#fetch_properties` operation"
        announce_error(message, result)
      end
    end

    private

    def grouped_actual_properties(properties)
      flag = credentials.test_mode == 'No' ? 'Real' : 'Test'
      actual_properties = properties.select { |property| property['RealOrTest'] == flag }
      actual_properties.each_slice(BATCH_SIZE)
    end

    def fetch_data_and_process(properties)
      ids = identifiers(properties)
      result = importer.fetch_data(ids)
      if result.success?
        properties_data = result.value
        properties_data.map do |property|
          if validator(property).valid?
            synchronisation.start(property['HouseCode']) { mapper.prepare(property) }
          end
        end
      else
        synchronisation.failed!
        message = "Failed to perform the `#fetch_data` operation, with identifiers: `#{ids}`"
        announce_error(message, result)
      end
    end

    def identifiers(properties)
      properties.map { |property| property['HouseCode'] }
    end

    def validator(property)
      ::AtLeisure::PropertyValidation.new(property)
    end

    def importer
      @importer ||= ::AtLeisure::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(SUPPLIER_NAME)
    end

    def mapper
      @mapper ||= ::AtLeisure::Mapper.new(layout_items: importer.fetch_layout_items.value)
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
        supplier:    SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end
