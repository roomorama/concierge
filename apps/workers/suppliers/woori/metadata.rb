module Workers::Suppliers::Woori
  # +Workers::Suppliers::Woori::Metadata+
  #
  # Performs synchronisation with supplier using files provided by supplier.
  #
  # There is no event listener for this worker, synchronisation should be
  # started manually.
  class Metadata
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

    def importer
      @importer ||= ::Woori::Importer.new(credentials)
    end

    def credentials
      Concierge::Credentials.for(::Woori::Client::SUPPLIER_NAME)
    end

    def all_properties
      @all_properties ||= importer.fetch_all_properties
    end

    def all_property_units(property_id)
      @all_units ||= importer.fetch_all_property_units(property_id)
    end
  end
end
