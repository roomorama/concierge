module Workers::Suppliers

  class Audit
    SUPPLIER_NAME = "Audit"
    attr_reader :property_sync, :calendar_sync, :host

    def initialize(host)
      @host = host
      @property_sync = Workers::PropertySynchronisation.new(host)
      @calendar_sync = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      result = importer.fetch_properties
      if result.success?
        result.value.each do |json|
          property_sync.start(json['identifier']) do
            importer.json_to_property(json) do |calendar_entries|
              calendar_sync.start(json['identifier']) do
                calendar = Roomorama::Calendar.new(json['identifier'])
                calendar_entries.each {|entry| calendar.add entry }
                Result.new(calendar)
              end
            end
          end
        end

        property_sync.finish!
        calendar_sync.finish!
      else
        message = "Failed to perform the `#fetch_properties` operation"
        announce_error(message, result)
      end
    end

    private

    def importer
      @properties ||= ::Audit::Importer.new(credentials)
    end

    def credentials
      @credentials ||= Concierge::Credentials.for(SUPPLIER_NAME)
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

Concierge::Announcer.on("sync.#{Workers::Suppliers::Audit::SUPPLIER_NAME}") do |host|
  Workers::Suppliers::Audit.new(host).perform
end
