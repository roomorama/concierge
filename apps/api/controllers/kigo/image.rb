module API::Controllers::Kigo
  class Image
    include API::Action

    params do
      param :property_id, presence: true
      param :image_id, presence: true
    end

    expose :identifier

    def call(params)
      if params.valid?
        result = fetcher(params).fetch
        if result.success?
          self.status = 200
          self.body   = result.value
          self.headers.merge!({ 'Content-Type' => 'image/jpeg' })
        else
          status 503, invalid_request(result.error.code)
        end
      else
        status 404
      end
    end

    private

    def fetcher(params)
      Kigo::ImageFetcher.new(params[:property_id], params[:image_id])
    end

    def invalid_request(error)
      { status: 'error', errors: error }.to_json
    end
  end
end
