require_relative "../internal_error"

module Web::Controllers::ExternalErrors
  class Show
    include Web::Action
    include Web::Controllers::InternalError

    expose :error

    def call(params)
      @error = ExternalErrorRepository.find(params[:id])

      unless @error
        render_404_template
      end
    end

    private

    def render_404_template
      template = Web::Controllers::TemplateRenderer.new("404.html.erb").render
      status 404, template
    end
  end
end
