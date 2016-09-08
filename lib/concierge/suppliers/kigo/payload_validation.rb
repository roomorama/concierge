module Kigo
  # +Kigo::PayloadValidation+
  #
  # this class responsible for validating data fetched form supplier API
  # Attributes:
  # * +payload+ - Hash based property data
  # * +ib_flag+ - A boolean helps define which flag means that property is instant booking.
  #               Kigo and KigoLegacy have opposite meanings of the +PROP_INSTANT_BOOK+ attribute
  class PayloadValidation
    INVALID_PROPERTY_TYPE_IDS = [13, 18, 19] # hostel, resort, hotel

    attr_reader :payload, :ib_flag

    def initialize(payload, ib_flag: true)
      @payload = Concierge::SafeAccessHash.new(payload)
      @ib_flag = ib_flag
    end

    def valid?
      instant_booking? && !hotel_type? && has_images?
    end

    private

    def instant_booking?
      payload['PROP_INSTANT_BOOK'] == ib_flag
    end

    def hotel_type?
      property_type_id = payload.get('PROP_INFO.PROP_TYPE_ID')
      INVALID_PROPERTY_TYPE_IDS.include?(property_type_id)
    end

    def has_images?
      Array(payload['PROP_PHOTOS']).any?
    end
  end
end