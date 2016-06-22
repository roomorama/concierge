module AtLeisure
  class PropertyValidation

    attr_reader :property

    def initialize(property)
      @property = property
    end

    def valid?
      no_errors? &&
        valid_payload? &&
        instant_bookable? &&
        no_deposit_upfront?
    end

    private

    def no_errors?
      property['error'].nil?
    end

    def valid_payload?
      return true if PayloadValidation.new(property).valid?
      augment_context
      false
    end

    def instant_bookable?
      property['AvailabilityPeriodV1'].any? { |availability| availability['OnRequest'] == 'No' }
    end

    def no_deposit_upfront?
      deposit['Items'].find { |item| item['Payment'] == 'MandatoryDepositUpFront' }.nil?
    end

    def deposit
      property['CostsOnSiteV1'].find { |cost| find_en(cost) == 'Deposit' }
    end

    def find_en(item)
      item['TypeDescriptions'].find { |desc| desc['Language'] == 'EN' }['Description']
    end

    def augment_context
      missing_basic_data = Concierge::Context::MissingBasicData.new(
        error_message: 'invalid payload',
        attributes: property
      )

      Concierge.context.augment(missing_basic_data)
    end

  end
end

