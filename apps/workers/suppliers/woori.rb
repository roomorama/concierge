module Workers::Suppliers
  # +Workers::Suppliers::Woori+
  #
  # Performs synchronisation with supplier
  class Woori
    attr_reader :synchronisation, :host
    
    INIT_SYNC_DATE = "1970-01-01"

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      last_updated_at = last_synced_date

      result = importer.stream_properties(updated_at: last_updated_at) do |properties|
        properties.each do |property|
          synchronisation.start(property.identifier) do
            Result.new(property)
          end
        end
      end

      if result.success?
        synchronisation.finish!
      else
        message = "Error while `#stream_properties` operation"
        announce_error(message, result)
      end
    end

    private

    def importer
      @importer ||= ::Woori::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(::Woori::Client::SUPPLIER_NAME)
    end

    # Returns the last successful time stamp of a synchronisation
    # Could be nil if there has never been a successful sync yet
    def last_synced_date
      most_recent = SyncProcessRepository.recent_successful_sync_for_host(host).first

      if most_recent
        most_recent&.started_at.strftime("%Y-%m-%d")
      else
        INIT_SYNC_DATE
      end
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
