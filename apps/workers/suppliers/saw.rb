module Workers::Suppliers
  class SAW
    attr_reader :synchronisation, :host

    def initialize(host)
      @host = host
      @synchronisation = Workers::Synchronisation.new(host)
    end

    def perform
      countries = importer.fetch_countries

      properties = []

      properties.each do |property|
        synchronisation.start(property["id"]) do
          roomorama_property = Roomorama::Property.new(property["id"])

          # sync images
          # sync units
          # sync availabilities

          Result.new(roomorama_property)
        end
      end

      synchronisation.finish!
    end

    private

    def importer
      @properties ||= SAW::Importer.new(credentials)
    end

    def credentials
      @credentials ||= Concierge::Credentials.for("SAW")
    end
  end

end

Concierge::Announcer.on("sync.SAW") do |host|
  Workers::Suppliers::SAW.new(host).perform
end
