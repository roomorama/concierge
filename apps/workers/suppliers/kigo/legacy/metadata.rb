require_relative '../metadata'
module Workers::Suppliers::Kigo::Legacy
  # +Workers::Suppliers::Kigo::Legacy::Metadata+
  #
  # This class responsible for handling diff on identifiers
  # and calling process +Workers::Suppliers::Kigo::Legacy::Property+ only for each
  # updated property
  #
  class Metadata < Workers::Suppliers::Kigo::Metadata

    private

    def importer
      super  # Kigo and KigoLegacy uses the same importer
    end

    def update_property(property_identifier)
      Workers::Suppliers::KigoLegacy::Property.new(property_identifier).perform
    end

    def request_handler
      Kigo::LegacyRequest.new(credentials, timeout: 40)
    end
  end
end

Concierge::Announcer.on("metadata.#{Kigo::Legacy::SUPPLIER_NAME}") do |supplier, args|
  Workers::Suppliers::Kigo::Legacy::Metadata.new(supplier, args).perform
end
