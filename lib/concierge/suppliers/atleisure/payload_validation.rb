module AtLeisure
  # +AtLeisure::PayloadValidation+
  #
  # This class helps us to be confident with provided payload that it has the structure
  # as we expect, otherwise the payload will be tracked in
  class PayloadValidation
    PROPERTY_TYPE_CODE = 10

    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def valid?
      includes_generic_keys && images_key? && property_type_key?
    end

    private

    def includes_generic_keys
      missing_keys = required_keys - payload.keys
      if missing_keys.empty?
        true
      else
        keys    = missing_keys.map { |key| "`#{key}`" }
        message = "The payload for the property did not meet minimum requirements for importing. Missing keys: #{keys.join(', ')}"
        augment_context(message)
        false
      end
    end

    def images_key?
      images_payload = payload['MediaV2'].first
      if images_payload && images_payload['TypeContents']
        true
      else
        message = 'Unexpected images payload. Expects `TypeContents` key'
        augment_context(message)
        false
      end
    end

    def property_type_key?
      property_type = payload['PropertiesV1'].find { |item| item['TypeNumber'] == PROPERTY_TYPE_CODE }
      if property_type && property_type['TypeContents']&.first
        true
      else
        message = 'Unexpected payload for property type'
        augment_context(message)
        false
      end
    end

    def required_keys
      %w(HouseCode BasicInformationV3 MediaV2 LanguagePackENV4
         PropertiesV1 LayoutExtendedV2 AvailabilityPeriodV1 CostsOnSiteV1)
    end

    def augment_context(message)
      context = Concierge::Context::MissingBasicData.new(
        error_message: message,
        attributes:    payload
      )

      Concierge.context.augment(context)
    end
  end
end