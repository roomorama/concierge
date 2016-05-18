module Web::Controllers::Dashboard
  class Index
    include Web::Action

    expose :concierge

    def call(params)
      @concierge = Web::Support::StatusCheck.new
    end
  end
end
