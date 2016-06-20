module AtLeisure
  class Verifier

    attr_reader :property

    def verify(property_data)
      @property = property_data
      return false if has_error?
      return false unless instant_bookable?
      return false if deposit_up_front_cost?
      true
    end

    private

    def has_error?
      property.has_key?('error')
    end

    def instant_bookable?
      property['AvailabilityPeriodV1'].any? { |availability| availability['OnRequest'] == 'No' }
    end

    def has_prohibited_costs?
      deposit_up_front_cost?
    end

    def deposit_up_front_cost?
      deposit['Items'].any? { |item| item['Payment'] == 'MandatoryDepositUpFront' }
    end

    def deposit
      property['CostsOnSiteV1'].find { |cost| find_en(cost) == 'Deposit' }
    end

    def find_en(item)
      item['TypeDescriptions'].find { |desc| desc['Language'] == 'EN' }['Description']
    end

  end
end

