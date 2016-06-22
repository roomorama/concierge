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

    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def valid?
      no_errors? &&
        valid_payload? &&
        instant_bookable? &&
        no_deposit_upfront?
    end

    private

    def no_errors?
      payload['error'].nil?
    end

    def valid_payload?
      return true if PayloadValidation.new(payload).valid?
      augment_context
      false
    end

    def instant_bookable?
      payload['AvailabilityPeriodV1'].any? { |availability| availability['OnRequest'] == 'No' }
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

    def augment_context
      missing_basic_data = Concierge::Context::MissingBasicData.new(
        error_message: 'invalid payload',
        attributes:    payload
      )

      Concierge.context.augment(missing_basic_data)
    end

  end
end

