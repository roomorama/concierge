module AtLeisure
  class PayloadValidation

    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def valid?
      required_keys.all? { |key| payload.key? key }
    end

    private

    def required_keys
      %w(HouseCode BasicInformationV3 MediaV2 LanguagePackENV4
         PropertiesV1 LayoutExtendedV2 AvailabilityPeriodV1 CostsOnSiteV1)
    end
  end
end