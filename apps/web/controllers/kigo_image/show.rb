require_relative "../internal_error"
require_relative "../params/paginated"

module Web::Controllers::KigoImage
  class Show
    include Web::Action

    params do
      param :property_id, presence: true
      param :image_id,    presence: true
    end

    expose :identifier

    def call(params)
      if params.valid?
        property_id = params[:property_id].to_i
        image_id    = params[:image_id]
        image       = fetcher.fetch(property_id, image_id)

        self.status = 200
        self.body   = image
        self.headers.merge!({ 'Content-Type' => 'image/jpeg' })
      else

      end
    end

    private

    def fetcher
      Kigo::ImageFetcher.new
    end
  end
end
