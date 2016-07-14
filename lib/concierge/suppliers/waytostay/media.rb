module Waytostay
  #
  # Handles the fetching of images from Waytostay
  #
  module Media
    ENDPOINT = "/properties/:property_reference/media".freeze
    REQUIRED_RESPONSE_KEYS = [ "_embedded.property_media" ].freeze

    # Return a +Result+ wrapping a +Roomorama::Property+ instance, attaching
    # any images available from Waytostay.
    #
    # Does not announce any error (does not persist as +ExternalError+),
    # because we should only need to call this from a synchronisation.start block,
    # which announces errors after wards.
    #
    def update_media(roomorama_property)
      first_page_path = build_path(ENDPOINT, property_reference: roomorama_property.identifier)
      # ignore any existing images
      roomorama_property.drop_images!
      update_media_per_page(roomorama_property, first_page_path)
    end

    private

    def update_media_per_page(roomorama_property, page_path)
      if page_path.nil?
        return Result.new(roomorama_property) # return the result, this is the last page
      end

      result = oauth2_client.get(page_path, headers: headers)
      return result unless result.success?

      response = Concierge::SafeAccessHash.new(result.value)
      missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)

      if missing_keys.empty?
        parse_media!(response, roomorama_property)
        update_media_per_page(roomorama_property, next_page_path(response))
      else
        augment_missing_fields(missing_keys)
        Result.error(:unrecognised_response)
      end
    end

    def parse_media!(response, roomorama_property)
      response.get("_embedded.property_media").each do |wts_media|
        next if wts_media["type"] != "image"
        identifier = Digest::MD5.hexdigest(wts_media["url"])
        image = Roomorama::Image.new(identifier)
        image.url = wts_media["url"]
        roomorama_property.add_image(image)
      end
    end

    # return the link for the next page, or nil if it is the last page
    def next_page_path(response)
      response.get("_links.next.href")
    end
  end
end
