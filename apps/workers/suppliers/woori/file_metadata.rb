module Workers::Suppliers::Woori
  # +Workers::Suppliers::Woori::FileImporter+
  #
  # Performs synchronisation with supplier using files provided by supplier.
  #
  # There is no event listener for this worker, synchronisation should be 
  # started manually.
  class FileMetadata
    class UnitRatesFetchError < StandardError; end

    attr_reader :synchronisation, :host
    
    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      all_properties.each do |property|
        synchronisation.start(property.identifier) do
          units = all_property_units(property.identifier)
          units.each { |unit| property.add_unit(unit) }

          Result.new(property)
        end
      end

      synchronisation.finish!
    end

    private

    def file_importer
      @file_importer ||= ::Woori::FileImporter.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(::Woori::Client::SUPPLIER_NAME)
    end

    def all_properties
      @all_properties ||= file_importer.fetch_all_properties
    end

    def all_property_units(property_id)
      @all_units ||= file_importer.fetch_all_property_units(property_id)
    end
  end
end
