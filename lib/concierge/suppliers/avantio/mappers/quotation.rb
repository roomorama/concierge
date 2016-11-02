module Avantio
  module Mappers
    class Quotation

      def build(result_hash)
        Avantio::Entities::Quotation.new(
          fetch_room_only_final(result_hash),
          fetch_currency(result_hash)
        )
      end

      def fetch_room_only_final(result_hash)
        result_hash.get('get_booking_price_rs.booking_price.room_only_final').to_f
      end

      def fetch_currency(result_hash)
        result_hash.get('get_booking_price_rs.booking_price.currency')
      end
    end
  end
end