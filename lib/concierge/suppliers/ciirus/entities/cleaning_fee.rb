module Ciirus
  module Entities
    class CleaningFee
      attr_reader :charge_cleaning_fee, :amount

      def initialize(charge_cleaning_fee, amount)
        @charge_cleaning_fee = charge_cleaning_fee
        @amount = amount
      end
    end
  end
end