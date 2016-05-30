module Web::Controllers

  # Web::Controllers::InternalError
  #
  # This module is responsible for the handling of exceptions that might happen
  # while a request is being processed in the web app. In case an exception is
  # raised, this # module catches it, sends a notification to Rollbar
  # and raises the 500 template. Unfortunately this process should be automatic,
  # but we have to add manual support to it at the moment.
  module InternalError

    def self.included(base)
      base.class_eval do
        handle_exception StandardError => :send_notification
      end
    end

    private

    def send_notification(error)
      Rollbar.error(error)
      render_500_template
    end

    # renders the 500.html.erb template within the current class context,
    # since no dynamic content is necessary, and returns it back to the
    # caller.
    def render_500_template
      template = Web::Controllers::TemplateRenderer.new("500.html.erb").render
      status 500, template
    end
  end

end
