module Workers::Suppliers
  class SAW
    attr_reader :synchronisation, :host

    def initialize(host)
      @host = host
      @synchronisation = Workers::Synchronisation.new(host)
    end

    def perform
      result = importer.fetch_countries

      if result.success?
        countries = result.value
      else
        # TODO! 
      end
      
      result = importer.fetch_properties_by_countries(countries)

      if result.success?
        basic_properties = result.value
      else
        # TODO! 
      end

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
