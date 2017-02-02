require_relative '../property'
module Workers::Suppliers::Kigo::Legacy
  # +Workers::Suppliers::Kigo::Legacy::Property+
  #
  # Performs synchronisation with supplier
  class Property < Workers::Suppliers::Kigo::Property

    CACHE_PREFIX = 'metadata.kigo_legacy'

    private

    def request_handler
      Kigo::LegacyRequest.new(credentials, timeout: 40)
    end

    def supplier_name
      Kigo::Legacy::SUPPLIER_NAME
    end

    def valid_payload?(payload)
      Kigo::PayloadValidation.new(payload, ib_flag: false).valid?
    end

    def mapper_resolver
      Kigo::Mappers::LegacyResolver.new
    end
  end
end
