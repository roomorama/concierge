module Roomorama

  class Image

    # +Roomorama::Image::ValidationError+
    #
    # Raised in case the parameters required for a valid image are not present
    # or invalid.
    class ValidationError < Roomorama::Error
      def initialize(message)
        super("Invalid image object: #{message}")
      end
    end

    attr_accessor :identifier, :url, :caption, :position

    def initialize(identifier)
      @identifier = identifier
    end

    # validate the presence and format of the +identifier+ and +url+ attributes.
    # +identifier+ must be defined and non-empty, whereas the +url+ must be a valid
    # HTTP resource identifier.
    #
    # Raises +Roomorama::Image::ValidationError+ in case one attribute
    # is invalid - returns +true+ otherwise.
    def validate!
      if identifier.to_s.empty?
        raise ValidationError.new("identifier was not given, or is empty")
      elsif url.to_s.empty? || !valid_url?
        raise ValidationError.new("URL was not given, or is empty")
      else
        true
      end
    end

    private

    def valid_url?
      URI.parse(url).kind_of?(URI::HTTP)
    rescue URI::InvalidURIError
      false
    end

  end

end
