module Web::Controllers::Params

  # +Web::Controllers::Params::Paginated+
  #
  # Parameters for controllers that allow resources to be presented in a paginated
  # manner. Included parameters:
  #
  #   +page+: which page should be presented.
  #   +per+:  how many records per page should be presented.
  #
  # Both parameters are optional.
  module Paginated
    def self.included(base)
      base.param :page, type: Integer
      base.param :per,  type: Integer
    end
  end

end
