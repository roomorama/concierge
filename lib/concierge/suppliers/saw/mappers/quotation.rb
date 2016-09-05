module SAW
  module Mappers
    # +SAW::Mappers::Quotation+
    #
    # This class is responsible for building a +Quotation+ object
    class Quotation
      # Builds a quotation
      #
      # Arguments:
      #
      #   * +params+ [Hash] property parameters
      #   * +property_rate+ [SAW::Entities::PropertyRate] property rate
      #
      # Returns [Quotation]
      def self.build(params, property_rate)
        requested_unit = property_rate.find_unit(params[:unit_id])

        ::Quotation.new(
          property_id: params[:property_id],
          unit_id:     params[:unit_id],
          check_in:    params[:check_in].to_s,
          check_out:   params[:check_out].to_s,
          guests:      params[:guests],
          currency:    property_rate.currency,
          total:       requested_unit.price,
          available:   requested_unit.available
        )
      end

      # Builds unavailable quotation.
      # Used in cases when rates information for unit is not available.
      #
      # Arguments:
      #
      #   * +params+ [Hash] parameters
      #
      # Returns [Quotation]
      def self.build_unavailable(params)
        ::Quotation.new(
          property_id: params[:property_id],
          unit_id:     params[:unit_id],
          check_in:    params[:check_in].to_s,
          check_out:   params[:check_out].to_s,
          guests:      params[:guests],
          available:   false
        )
      end
    end
  end
end
