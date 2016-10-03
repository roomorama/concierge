module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Quotation+
    #
    # This class is responsible for building a +Quotation+ object
    class Quotation
      attr_reader :price, :currency, :quotation_params

      # Initialize Quotation mapper
      #
      # Arguments:
      #
      #   * +price+ [Entities::Price] price
      #   * +currency+ [String] currency code
      #   * +quotation_params+ [Concierge::SafeAccessHash] quotation parameters
      def initialize(price, currency, quotation_params)
        @price = price
        @currency = currency
        @quotation_params = quotation_params
      end

      # Builds quotation
      #
      # Returns [Quotation]
      def build_quotation
        ::Quotation.new(
          property_id:         quotation_params[:property_id],
          check_in:            quotation_params[:check_in].to_s,
          check_out:           quotation_params[:check_out].to_s,
          guests:              quotation_params[:guests],
          total:               price.total,
          available:           price.available?,
          currency:            currency
        )
      end
    end
  end
end
