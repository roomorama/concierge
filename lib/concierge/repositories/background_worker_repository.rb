# +BackgroundWorkerRepository+
#
# Persistence and query methods for the +background_workers+ table.
class BackgroundWorkerRepository
  include Hanami::Repository

  # returns the total number of properties stored in the database.
  def self.count
    query.count
  end

  # retrieves a list of workers for a given supplier
  def self.for_supplier(supplier)
    query do
      where(supplier_id: supplier.id)
    end
  end

end
