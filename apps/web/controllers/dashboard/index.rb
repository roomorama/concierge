require_relative "../internal_error"

module Web::Controllers::Dashboard
  class Index
    include Web::Action
    include Web::Controllers::InternalError

    expose :concierge

    def call(params)
      @concierge = Web::Support::StatusCheck.new
    end
  end
end
