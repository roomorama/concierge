module AtLeisure
  # +AtLeisure::PayloadValidation+
  #
  # This class helps us to be confident with provided payload that it has the structure
  # as we expect, otherwise the payload will be tracked in
  class PayloadValidation

    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def valid?
      missing_keys = required_keys - payload.keys
      if missing_keys.empty?
        true
      else
        augment_context(missing_keys)
        false
      end
    end

    private

    def required_keys
      %w(HouseCode BasicInformationV3 MediaV2 LanguagePackENV4
         PropertiesV1 LayoutExtendedV2 AvailabilityPeriodV1 CostsOnSiteV1)
    end

    def augment_context(missing_keys)
      message = "The payload for the property did not meet minimum requirements for importing. Missing keys :#{missing_keys.join(', ')}"
      missing_basic_data = Concierge::Context::MissingBasicData.new(
        error_message: message,
        attributes:    payload
      )

      Concierge.context.augment(missing_basic_data)
    end
  end
end