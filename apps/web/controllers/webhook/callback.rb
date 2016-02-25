module Web::Controllers::Webhook
  class Callback
    include Web::Action

    def call(params)
      # handle our params with WebhookHandler
    end
  end
end
