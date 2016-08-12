module Kigo::Mappers
  # +Kigo::Mappers::LegacyResolver+
  #
  # this class responsible for handling differences between Kigo and Kigo Legacy
  # to avoid duplication in +Kigo::Mappers::Property+
  class LegacyResolver

    # images payload has two attributes for caption PHOTO_NAME and PHOTO_COMMENTS
    # the PHOTO_COMMENTS are almost always blank
    def images(payload)
      images = Array(payload)
      images.map do |image|
        identifier = image['PHOTO_ID']
        caption    = image['PHOTO_NAME']
        Roomorama::Image.new(identifier).tap do |i|
          i.url     = image_url(identifier)
          i.caption = caption
        end
      end
    end

    private

    def image_url(identifier)
      "https://concierge-staging.roomorama.com/kigo/legacy/image/#{identifier}"
    end
  end
end