module Ciirus
  module Mappers
    class Reservation
      class << self
        # Maps hash representation of Ciirus API GetReservations response
        # to Ciirus::Entities::Reservation
        def build(hash)
          Ciirus::Entities::Reservation.new(
            hash[:arrival_date],
            hash[:departure_date],
            hash[:booking_id],
            hash[:has_pool_heat],
            hash[:guest_name]
          )
        end
      end
    end
  end
end