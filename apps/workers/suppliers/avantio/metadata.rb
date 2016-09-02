module Workers::Suppliers::Avantio
  # +Workers::Suppliers::Avantio::Metadata+
  #
  # Performs properties synchronisation with supplier
  class Metadata
    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      properties = synchronisation.new_context do
        importer.fetch_properties(host)
      end

      if properties.success?
        descriptions = importer.fetch_descriptions(host)
        if descriptions.success?
          properties.value.each do |property|
            property_id = property.property_id

            # TODO add property validator

            synchronisation.start(property_id) do
              description = descriptions[property_id]
              unless description
                message = "Description not found for property `#{property_id}`"
                augment_context_error(message)
                next Result.error(:description_not_found)
              end
              Result.new(mapper.build(property, description))
            end
          end
          synchronisation.finish!
        else
          synchronisation.failed!
          message = 'Failed to perform the `#fetch_descriptions` operation'
          announce_error(message, result)
        end
      else
        synchronisation.failed!
        message = 'Failed to perform the `#fetch_properties` operation'
        announce_error(message, result)
      end
    end

    private

    def mapper
      @mapper ||= ::Avantio::Mappers::RoomoramaProperty.new
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
Concierge::Announcer.on('metadata.Avantio') do |host, args|
  Workers::Suppliers::Avantio::Metadata.new(host).perform
  Result.new({})
end
