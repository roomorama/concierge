module Workers::Suppliers::THH
  # +Workers::Suppliers::THH::Metadata+
  #
  # Performs properties synchronisation with supplier
  class Metadata
    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      result = synchronisation.new_context { importer.fetch_properties }

      if result.success?
        properties = result.value
        properties.each do |property|
          property_id = property['property_id']
          if validator(property).valid?
            synchronisation.start(property_id) do
              # Puts property info to context for analyze in case of error
              augment_property_info(property)

              roomorama_property = mapper.build(property)
              Result.new(roomorama_property)
            end
          else
            synchronisation.skip_property(property_id, 'Invalid property')
          end
        end
      else
        synchronisation.skip_purge!
        synchronisation.failed!
        message = 'Failed to perform the `#fetch_properties` operation'
        announce_error(message, result)
      end
      synchronisation.finish!
    end

    private

    def report_error(message)
      yield.tap do |result|
        augment_context_error(message) unless result.success?
      end
    end

    def mapper
      @mapper ||= ::THH::Mappers::RoomoramaProperty.new
    end

    def importer
      @importer ||= ::THH::Importer.new(credentials)
    end

    def validator(property)
      THH::Validators::PropertyValidator.new(property)
    end

    def credentials
      Concierge::Credentials.for(THH::Client::SUPPLIER_NAME)
    end

    def augment_property_info(property)
      message = {
        label: 'Property Info',
        message: property.to_json,
        backtrace: caller,
        content_type: 'json'
      }
      context = Concierge::Context::Message.new(message)
      Concierge.context.augment(context)
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
        supplier:    THH::Client::SUPPLIER_NAME,
        code:        result.error.code,
        description: result.error.data,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('metadata.THH') do |host, args|
  Workers::Suppliers::THH::Metadata.new(host).perform
  Result.new({})
end
