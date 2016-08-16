module SAW
  module Converters
    # +SAW::Converters::URLRewriter+
    #
    # URLRewriter is needed because SAW images has wrong URLs on staging.
    # SAW server doesn't redirect images from staging subdomain causing
    # us to getting 0-byte images
    class URLRewriter
      class << self
        # This method converts image URLs coming from the staging server to
        # proper format by changing their URLs to production server which
        # serves all images as expected.
        #
        # Arguments
        #
        #   * +url+ [String] original url coming from SAW API
        #
        # Usage
        #
        #   URLRewriter.build("http://link.com/file.jpg")
        #
        # Returns [String] rewritten url
        def build(url)
          url.gsub(%r[\Ahttp://staging], "http://www")
        end
      end
    end
  end
end
