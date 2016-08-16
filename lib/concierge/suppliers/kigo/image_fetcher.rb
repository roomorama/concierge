module Kigo
  class ImageFetcher

    def fetch(property_id, image_id)
      result = importer.fetch_image(property_id, image_id)
      if result.success?
        file_from_base64(result.value)
      else
        announce_error(result)
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
      StringIO.new(Base64.decode64(string))
    end

    def announce_error(result)
      message = {
        label:     'Kigo image fetching failure',
        message:   'failed to perform `#fetch_images` operation',
        backtrace: caller
      }
      context = Concierge::Context::Message.new(message)
      Concierge.context.augment(context)

      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   'sync',
        supplier:    Kigo::Legacy::SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end