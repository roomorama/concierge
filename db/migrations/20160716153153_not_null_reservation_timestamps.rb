Hanami::Model.migration do
  up do
    one_month_ago = Time.now - 30 * 24 * 60 * 60
    reservations  = ReservationRepository.all.to_a

    reservations.each do |reservation|
      reservation.created_at = one_month_ago
      reservation.updated_at = one_month_ago

      ReservationRepository.update(reservation)
    end

    alter_table :reservations do
      set_column_not_null :created_at
      set_column_not_null :updated_at
    end
  end

  down do
    alter_table :reservations do
      set_column_allow_null :created_at
      set_column_allow_null :updated_at
    end
  end
end
