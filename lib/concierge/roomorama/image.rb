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

    ATTRIBUTES = [:identifier, :url, :caption, :position]
    attr_accessor *ATTRIBUTES

    # allows the creation of an instance of +Roomorama::Image+ through
    # a hash of attributes. Useful when loading serialized representations
    # of images from the database.
    def self.load(attributes)
      instance = new(attributes[:identifier])

      ATTRIBUTES.each do |attr|
        if attributes[attr]
          instance[attr] = attributes[attr]
        end
      end

      instance
    end

    def initialize(identifier)
      @identifier = identifier
    end

    # allows the setting of specific attributes, using a Hash-like syntax.
    # Unknown attributes are ignored.
    #
    # Example
    #
    #   image = Roomorama::Image.new("img1")
    #   image[:caption] = "Swimming Pool"
    #   image.caption # => "Swimming Pool"
    #   image[:unknown] = "Attribute" # => no effect
    def []=(name, value)
      if ATTRIBUTES.include?(name)
        setter = [name, "="].join
        public_send(setter, value)
      end
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

    def to_h
      scrub({
        identifier: identifier,
        url:        url,
        caption:    caption,
        position:   position
      })
    end

    private

    def scrub(data)
      data.delete_if { |_, value| value.to_s.empty? }
    end

    def valid_url?
      URI.parse(url).kind_of?(URI::HTTP)
    rescue URI::InvalidURIError
      false
    end

  end

end
