module Kigo::Mappers
  # +Kigo::Mappers::Resolver+
  #
  # this class responsible for handling differences between Kigo and Kigo Legacy
  # to avoid duplication in +Kigo::Mappers::Property+
  class Resolver

    # images payload has two attributes for caption PHOTO_NAME and PHOTO_COMMENTS
    # the PHOTO_NAME is the short version of PHOTO_COMMENTS
    def images(payload, _)
      images = Array(payload)
      images.map do |image|
        url        = image['PHOTO_ID']
        identifier = url.split('/').last
        caption    = image['PHOTO_COMMENTS']
        Roomorama::Image.new(identifier).tap do |i|
          i.url     = URI.encode(['https:', url].join)
          i.caption = caption unless caption.strip.empty?
        end
      end
    end

  end
end
