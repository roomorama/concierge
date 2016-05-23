class Roomorama::Diff

  class Image
    # +Roomorama::Diff::Image::ValidationError+
    #
    # Raised in case the parameters required for a valid image change
    # are not present or valid.
    class ValidationError < Roomorama::Error
      def initialize(message)
        super("Invalid image diff: #{message}")
      end
    end

    attr_accessor :identifier, :caption

    def initialize(identifier)
      @identifier = identifier
    end

    # validates that the image change is valid. Checks:
    #
    # * identifier is given and non-empty
    # * the caption is set. Only image caption changes are supported by the Roomorama Diff API.
    def validate!
      if identifier.to_s.empty?
        raise ValidationError.new("identifier is required")
      elsif caption.to_s.empty?
        raise ValidationError.new("a change in the image caption is required")
      else
        true
      end
    end

    def to_h
      {
        identifier: identifier,
        caption:    caption
      }
    end

  end

end
