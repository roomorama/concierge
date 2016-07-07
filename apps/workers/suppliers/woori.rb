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
    end

  end
end

# Listen supplier worker
Concierge::Announcer.on("sync.Woori") do |host|
  Workers::Suppliers::Woori.new(host).perform
end