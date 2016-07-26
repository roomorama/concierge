module Ciirus
  module Entities
    class Extra
      attr_reader :property_id, :item_code, :item_description, :flat_fee, :flat_fee_amount, :daily_fee,
                  :daily_fee_amount, :percentage_fee, :percentage, :mandatory, :minimum_charge

      def initialize(attrs = {})
        @property_id      = attrs[:property_id]
        @item_code        = attrs[:item_code]
        @item_description = attrs[:item_description]
        @flat_fee         = attrs[:flat_fee]
        @flat_fee_amount  = attrs[:flat_fee_amount]
        @daily_fee        = attrs[:daily_fee]
        @daily_fee_amount = attrs[:daily_fee_amount]
        @percentage_fee   = attrs[:percentage_fee]
        @percentage       = attrs[:percentage]
        @mandatory        = attrs[:mandatory]
        @minimum_charge   = attrs[:minimum_charge]
      end
    end
  end
end