# +ReservationRepository+
#
# Persistence operations and queries for the +reservations+ table.
class ReservationRepository
  include Hanami::Repository

  # returns the total number of records on the +reservations+ table.
  def self.count
    query.count
  end

  # orders the reservation results by descending order of creation
  # date.
  def self.reverse_date
    query.desc(:created_at)
  end
end
