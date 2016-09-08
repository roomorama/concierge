module Kigo
  class ImageFetcher

    attr_reader :property_id, :image_id

    def initialize(property_id, image_id)
      @property_id = property_id.to_i
      @image_id    = image_id
    end

    def fetch
      result = importer.fetch_image(property_id, image_id)
      if result.success?
        file_from_base64(result.value)
      else
        result
      end
    end

    private

    def credentials
      @credentials ||= Concierge::Credentials.for(Kigo::Legacy::SUPPLIER_NAME)
    end

    def importer
      Kigo::Importer.new(credentials, request_handler)
    end

    def request_handler
      Kigo::LegacyRequest.new(credentials, timeout: 60)
    end

    def file_from_base64(string)
      file = StringIO.new(Base64.decode64(string))
      Result.new(file)
    end

  end
end