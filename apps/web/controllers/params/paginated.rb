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
  class Paginated < Web::Action::Params
    param :page, type: Integer
    param :per,  type: Integer
  end

end
