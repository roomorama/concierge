module Workers::Suppliers::Woori
  # +Workers::Suppliers::Woori::FileImporter+
  #
  # Performs synchronisation with supplier using files provided by supplier.
  #
  # There is no event listener for this worker, synchronisation should be 
  # started manually.
  class FileMetadata
    attr_reader :synchronisation, :host
    
    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      all_properties.each do |property|
        synchronisation.start(property.identifier) do
          Concierge.context.disable!

          units = all_property_units(property.identifier)
          units.each do |unit|

            unit.number_of_units = 1
            unit.nightly_rate = 10000.0
            unit.weekly_rate = 70000.0
            unit.monthly_rate = 300000.0

            property.add_unit(unit)
          end

          property.nightly_rate = 10000.0
          property.weekly_rate = 70000.0
          property.monthly_rate = 300000.0

          property.type = 'apartment'
          Result.new(property)
        end
      end

      synchronisation.finish!
    end

    private

    def file_importer
      @file_importer ||= ::Woori::FileImporter.new
    end

    def all_properties
      @all_properties ||= file_importer.fetch_all_properties
    end

    def all_property_units(property_id)
      @all_units ||= file_importer.fetch_all_property_units(property_id)
    end
  end
end
