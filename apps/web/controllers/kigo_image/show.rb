module Web::Controllers::KigoImage
  class Show
    include Web::Action

    params do
      param :property_id, presence: true
      param :image_id, presence: true
    end

    expose :identifier

    def call(params)
      if params.valid?
        result = fetcher.fetch(params)
        if result.success?
          self.status = 200
          self.body   = image
          self.headers.merge!({ 'Content-Type' => 'image/jpeg' })
        else
          status 503, invalid_request(result.error)
        end
      else
        status 404
      end
    end

    private

    def fetcher
      Kigo::ImageFetcher.new
    end

    def invalid_request(error)
      { status: 'error', errors: error }.to_json
    end
  end
end
