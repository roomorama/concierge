require_relative "pagination"

# +ExternalErrorRepository+
#
# Persistence operations and queries of the +external_errors+ table.
class ExternalErrorRepository
  include Hanami::Repository
  extend  Concierge::Repositories::Pagination

  # returns the total number of external errors stored in the database.
  def self.count
    query.count
  end

  # returns the most recent +ExternalError+ instance added to the database.
  # If the table is empty, this method returns +nil+.
  def self.most_recent
    scope = query { reverse_order(:happened_at).limit(1) }
    scope.to_a.first
  end

  def self.from_supplier_named(s)
    query do
      where(supplier: s)
    end
  end

  # returns a sorted scope of external errors where the most recent error
  # is first.
  def self.reverse_occurrence
    query do
      desc(:happened_at)
    end
  end

  # filters external errors with the given error +code+.
  def self.with_code(code)
    query do
      where(code: code)
    end
  end

end
