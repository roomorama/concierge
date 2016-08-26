module Workers::Suppliers::RentalsUnited
  # +Workers::Suppliers::RentalsUnited+
  #
  # Performs synchronisation with supplier
  class Metadata
    attr_reader :synchronisation, :host

    def initialize(host)
      @host = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
    end

    private

    def importer
      @properties ||= ::RentalsUnited::Importer.new(credentials)
    end

    def credentials
      @credentials ||= Concierge::Credentials.for(
        ::RentalsUnited::Client::SUPPLIER_NAME
      )
    end
  end
end

Concierge::Announcer.on("metadata.RentalsUnited") do |host|
  Workers::Suppliers::RentalsUnited::Metadata.new(host).perform
end
