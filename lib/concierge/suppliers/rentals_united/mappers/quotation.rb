module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Quotation+
    #
    # This class is responsible for building a +Quotation+ object
    class Quotation
      attr_reader :quotation_params, :price

      # Initialize Quotation mapper
      #
      # Arguments:
      #
      #   * +quotation_params+ [Concierge::SafeAccessHash] quotation parameters
      #   * +price+ [String] quotation price
      def initialize(quotation_params, price)
        @quotation_params = quotation_params
        @price = price
      end

      # Builds quotation
      #
      # Returns [Quotation]
      def build_quotation
        ::Quotation.new(
          property_id: quotation_params[:property_id],
          check_in:    quotation_params[:check_in].to_s,
          check_out:   quotation_params[:check_out].to_s,
          guests:      quotation_params[:guests],
          currency:    currency,
          total:       price ? price : 0,
          available:   price ? true : false
        )
      end

      def currency
        nil
      end
    end
  end
end
