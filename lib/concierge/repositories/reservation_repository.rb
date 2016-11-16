# +ReservationRepository+
#
# Persistence operations and queries for the +reservations+ table.
class ReservationRepository
  include Hanami::Repository
  extend  Concierge::Repositories::Pagination

  # returns the total number of records on the +reservations+ table.
  def self.count
    query.count
  end

  # orders the reservation results by descending order of creation
  # date.
  def self.reverse_date
    query.desc(:created_at)
  end

  def self.by_supplier(supplier)
    query { where(supplier: supplier) }
  end

  def self.by_reference_number(reference_number)
    query { where(reference_number: reference_number) }
  end
end
