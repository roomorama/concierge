module AtLeisure
  # +AtLeisure::PropertyValidation+
  #
  # This class responsible for properties validation.
  # cases when property invalid:
  #
  #   * payload has error key - the property doesn't persist on AtLeisure side
  #   * invalid payload       - if for some reasons AtLeisure API changed structure of data
  #   * on request property   - doesn't support Roomorama
  #   * deposit upfront       - doesn't support Roomorama
  #
  class PropertyValidation

    IGNORE_ROOM_TYPES = [
      130, # Hotel
      172, # Mill
      175  # Tent Lodge
    ]

    attr_reader :payload, :today

    # today is date for relevance check of availabilities
    def initialize(payload, today)
      @payload = payload
      @today = today
    end

    def valid?
      no_errors? &&
        valid_payload? &&
        instant_bookable? &&
        no_deposit_upfront? &&
        acceptable_type?
    end

    private

    def no_errors?
      payload['error'].nil?
    end

    def valid_payload?
      PayloadValidation.new(payload).valid?
    end

    def instant_bookable?
      payload['AvailabilityPeriodV1'].any? { |availability| availability_validator(availability).valid? }
    end

    def acceptable_type?
      properties_array = Array(payload['PropertiesV1'])
      room_type_hash   = properties_array.find { |data_hash| data_hash['TypeNumber'] == code_for(:property_type) }.to_h
      room_type_number = Array(room_type_hash['TypeContents']).first
      !IGNORE_ROOM_TYPES.include?(room_type_number)
    end

    def no_deposit_upfront?
      deposit['Items'].find { |item| item['Payment'] == 'MandatoryDepositUpFront' }.nil?
    end

    def deposit
      payload['CostsOnSiteV1'].find { |cost| find_en(cost) == 'Deposit' }
    end

    def find_en(item)
      item['TypeDescriptions'].find { |desc| desc['Language'] == 'EN' }['Description']
    end

    def availability_validator(availability)
      ::AtLeisure::AvailabilityValidator.new(availability, today)
    end

    def code_for(item)
      AtLeisure::Mapper::CODES.fetch(item)
    end
  end
end

