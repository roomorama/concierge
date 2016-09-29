module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Quotation+
    #
    # This class is responsible for building a +Quotation+ object
    class Quotation
      attr_reader :price, :currency, :host_fee_percentage, :quotation_params

      # Initialize Quotation mapper
      #
      # Arguments:
      #
      #   * +price+ [Entities::Price] price
      #   * +currency+ [String] currency code
      #   * +host_fee_percentage+ [Integer]
      #   * +quotation_params+ [Concierge::SafeAccessHash] quotation parameters
      def initialize(price, currency, host_fee_percentage, quotation_params)
        @price = price
        @currency = currency
        @host_fee_percentage = host_fee_percentage
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
          currency:            currency,
          host_fee_percentage: host_fee_percentage
        )
      end
    end
  end
end
