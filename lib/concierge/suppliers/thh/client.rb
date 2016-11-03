module THH
  #  +THH::Client+

  class Client
    SUPPLIER_NAME = 'THH'

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end
  end
end
