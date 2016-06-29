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
        #   * +rewrite+ [Boolean] boolean flag indicating whether convertion is
        #   needed. false by default
        #
        # Usage
        #
        #   URLRewriter.build("http://link.com/file.jpg", rewrite: true)
        #
        # Returns [String] rewritten url
        def build(url, rewrite: false)
          if rewrite
            url.gsub(/\Ahttp:\/\/staging/, 'http://www')
          else
            url 
          end
        end
      end
    end
  end
end
