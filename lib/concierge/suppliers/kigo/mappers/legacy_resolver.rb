module Kigo::Mappers
  # +Kigo::Mappers::LegacyResolver+
  #
  # this class responsible for handling differences between Kigo and Kigo Legacy
  # to avoid duplication in +Kigo::Mappers::Property+
  class LegacyResolver

    # generates the list of images with urls pointed to +Web::Controllers::KigoImage::Show+
    # images payload has two attributes for caption PHOTO_NAME and PHOTO_COMMENTS
    # the PHOTO_COMMENTS are almost always blank
    def images(payload, property_id)
      images = Array(payload)
      images.map do |image|
        identifier = image['PHOTO_ID']
        caption    = image['PHOTO_NAME']
        Roomorama::Image.new(identifier).tap do |i|
          i.url     = image_url(property_id, identifier)
          i.caption = caption
        end
      end
    end

    private

    def image_url(property_id, identifier)
      [ENV['CONCIERGE_URL'], 'kigo/image', property_id, identifier].join('/')
    end
  end
end