module API::Controllers::Kigo
  # +API::Controllers::Kigo::Image+
  #
  # this class responsible for sending images from KigoLegacy API
  class Image
    include API::Action

    params do
      param :property_id, presence: true
      param :image_id, presence: true
    end

    def call(params)
      if params.valid?
        return not_found_response if property_not_found(params[:property_id])

        result = fetcher(params).fetch
        if result.success?
          self.status = 200
          self.body   = result.value
          self.headers.merge!({ 'Content-Type' => 'image/jpeg' })
        else
          announce_error(result)
          status 503, invalid_request(result.error.code)
        end
      else
        not_found_response
      end
    end

    private

    def property_not_found(identifier)
      PropertyRepository.from_supplier(supplier).identified_by(identifier).empty?
    end

    def supplier
      SupplierRepository.named('KigoLegacy')
    end

    def fetcher(params)
      Kigo::ImageFetcher.new(params[:property_id], params[:image_id])
    end

    def invalid_request(error)
      { status: 'error', errors: error }.to_json
    end

    def not_found_response
      status 404, { property_id: 'property not found' }.to_json
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
