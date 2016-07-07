module Workers::Suppliers
  # +Workers::Suppliers::Woori+
  #
  # Performs synchronisation with supplier
  class Woori
    SUPPLIER_NAME = 'Woori'
    BATCH_SIZE = 50

    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::Synchronisation.new(host)
    end

    def perform
      result = importer.fetch_properties
      #To be implemented
    end

    private

    def importer
      @importer ||= ::Woori::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(SUPPLIER_NAME)
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

# Listen supplier worker
Concierge::Announcer.on("sync.Woori") do |host|
  Workers::Suppliers::Woori.new(host).perform
end