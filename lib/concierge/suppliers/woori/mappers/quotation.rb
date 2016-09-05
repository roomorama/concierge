module Woori
  module Mappers
    # +Woori::Mappers::Quotation+
    #
    # This class is responsible for building a +Quotation+ object
    class Quotation
      attr_reader :params, :safe_hash

      # Initialize Quotation mapper
      #
      # Arguments:
      #
      #   * +params+ [Concierge::SafeAccessHash] quotation parameters
      #   * +safe_hash+ [Concierge::SafeAccessHash] woori response
      def initialize(params, safe_hash)
        @params = params
        @safe_hash = safe_hash
      end

      # Builds a quotation
      #
      # Returns [Quotation]
      def build
        ::Quotation.new(
          property_id: params[:property_id],
          unit_id:     params[:unit_id],
          check_in:    params[:check_in].to_s,
          check_out:   params[:check_out].to_s,
          guests:      params[:guests],
          currency:    currency,
          total:       total_price,
          available:   available?
        )
      end

      private

      def day_entries
        Array(safe_hash.get("data"))
      end

      def available?
        day_entries.all? { |day_entry| available_day_entry?(day_entry) }
      end

      def available_day_entry?(day_entry)
        hash = Concierge::SafeAccessHash.new(day_entry)
        day_entry_active?(hash) && have_vacancy?(hash)
      end

      def day_entry_active?(hash)
        hash.get("active") == true
      end

      def have_vacancy?(hash)
        hash.get("vacancy").to_i > 0
      end

      def total_price
        day_entries.inject(0) do |sum, day_entry|
          hash = Concierge::SafeAccessHash.new(day_entry)
          sum + hash.get("price").to_i
        end
      end

      def currency
        hash = Concierge::SafeAccessHash.new(day_entries.first)
        hash.get("currency")
      end
    end
  end
end
