module Web::Controllers::Dashboard
  class Index
    include Web::Action

    expose :concierge

    def call(params)
      @concierge = Support::StatusCheck.new
    end
  end
end
