# +ExternalErrorRepository+
#
# Persistence operations and queries of the `external_errors` table.
class ExternalErrorRepository
  include Hanami::Repository

  DEFAULT_PER_PAGE = 10

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

  # paginates the collection of external errors according to the parameters given.
  #
  # page - the page to be returned.
  # per  - the number of results per page.
  #
  # If +page+ is not given, this method will return the first page. If +per+
  # is not given, this method will assume 10 results per page.
  def self.paginate(page: nil, per: nil)
    page = (page.to_i > 0) ? page.to_i : 1
    per  = (per.to_i  > 0) ? per.to_i  : DEFAULT_PER_PAGE

    offset = (page - 1) * per
    query { desc(:happened_at).offset(offset).limit(per) }
  end
end
