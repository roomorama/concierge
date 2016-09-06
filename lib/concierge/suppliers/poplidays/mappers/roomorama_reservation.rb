module Poplidays
  module Mappers
    class RoomoramaReservation
      # Maps hash representation of Poplidays API booking/easy response
      # to Reservation
      def build(params, hash)
        ::Reservation.new(params).tap do |r|
          r.reference_number = hash.fetch('id')
        end
      end
    end
  end
end