class Concierge::Context

  # +Concierge::Context::MissingBasicData+
  #
  # This class indicates the event when a property being synchronised between a
  # supplier and Roomorama lacks basic data to be published, such as identifiers
  # or images. It includes the Hash of attributes that was generated so that
  # it is possible to analyse the information later and communicate with the supplier.
  #
  # Usage
  #
  #   mismatch = Concierge::Context::MissingBasicData.new(
  #     error_message: "Image validation error: no identifier given",
  #     attributes:    { title: "Nice Unit", ... }
  #   )
  class MissingBasicData

    CONTEXT_TYPE = "missing_basic_data"

    attr_reader :error_message, :attributes, :timestamp

    def initialize(error_message:, attributes:)
      @error_message = error_message
      @attributes    = attributes
      @timestamp     = Time.now
    end

    def to_h
      {
        type:          CONTEXT_TYPE,
        timestamp:     timestamp,
        error_message: error_message,
        attributes:    attributes
      }
    end
  end

end
