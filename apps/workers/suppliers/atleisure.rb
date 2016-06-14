module Workers::Suppliers
  class AtLeisure

    attr_reader :synchronisation, :host, :failed

    def initialize(host)
      @host            = host
      @synchronisation = Workers::Synchronisation.new(host)
    end

    def perform
      result = importer.fetch_properties
      if result.success?
        grouped_properties = result.value
        grouped_properties.each do |properties|
          fetch_data_and_process(properties)
        end
        synchronisation.finish! unless failed
      else
        announce_error('sync', result)
      end
    end

    private

    def fetch_data_and_process(properties)
      result = importer.fetch_data(properties)
      if result.success?
        properties_data = result.value
        properties_data.each do |property|
          synchronisation.start { mapper.prepare(property) }
        end
      else
        @failed = true
        announce_error('sync', result)
      end
    end

    def importer
      @importer ||= ::AtLeisure::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for("AtLeisure")
    end

    def mapper
      @mapper ||= ::AtLeisure::Mapper.new(importer.layout_items)
    end

    def announce_error(operation, result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   operation,
        supplier:    "AtLeisure",
        code:        result.error.code,
        message:     "DEPRECATED",
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end