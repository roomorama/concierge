module Concierge::Repositories
  module Pagination

    DEFAULT_PER_PAGE = 10

    # paginates the collection of external errors according to the parameters given.
    #
    # page - the page to be returned.
    # per  - the number of results per page.
    #
    # If +page+ is not given, this method will return the first page. If +per+
    # is not given, this method will assume 10 results per page.
    def paginate(page: nil, per: nil)
      page = (page.to_i > 0) ? page.to_i : 1
      per  = (per.to_i  > 0) ? per.to_i  : DEFAULT_PER_PAGE

      offset = (page - 1) * per

      query do
        offset(offset).limit(per)
      end
    end
  end
end
