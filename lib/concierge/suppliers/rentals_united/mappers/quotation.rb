module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Quotation+
    #
    # This class is responsible for building a +Quotation+ object
    class Quotation
      attr_reader :quotation_params, :price, :currency_code

      # Initialize Quotation mapper
      #
      # Arguments:
      #
      #   * +quotation_params+ [Concierge::SafeAccessHash] quotation parameters
      #   * +price+ [String] quotation price
      #   * +currency_code+ [String] currency code
      def initialize(quotation_params, price, currency_code)
        @quotation_params = quotation_params
        @currency_code = currency_code
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
          currency:    currency_code,
          total:       price ? price : 0,
          available:   price ? true : false
        )
      end
    end
  end
end
