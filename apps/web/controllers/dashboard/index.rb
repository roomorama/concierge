require_relative "../internal_error"

module Web::Controllers::Dashboard
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    expose :concierge, :suppliers

    def call(params)
      @concierge = Web::Support::StatusCheck.new
      @suppliers = SupplierRepository.all
    end
  end
end
