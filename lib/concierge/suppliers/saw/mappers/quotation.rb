module SAW
  module Mappers
    class Quotation
      def self.build(params, property_rate)
        requested_unit = property_rate.find_unit(params[:unit_id].to_i)

        ::Quotation.new(
          property_id: params[:property_id],
          check_in:    params[:check_in].to_s,
          check_out:   params[:check_out].to_s,
          guests:      params[:guests],
          currency:    property_rate.currency,
          total:       requested_unit.price,
          available:   true
        )
      end
    end
  end
end
