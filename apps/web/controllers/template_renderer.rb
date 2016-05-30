module Web::Controllers

  # +Web::Controllers::TemplateRenderer+
  #
  # This class is able to manually render +web+ templates, in situations where
  # the request flow must be halted and a specific template returned to the
  # client. The most common scenario is when a specific condition is reached
  # and a +404+ or +500+ template must be rendered and returned.
  #
  # Usage
  #
  #   template = Web::Controllers::TemplateRenderer.new("500.html.erb").render
  #   # => "html string"
  #
  # Paths are relative to the +apps/web/templates+ directory.
  class TemplateRenderer

    attr_reader :name

    def initialize(template_name)
      @name = template_name
    end

    def render
      context = binding
      path    = Hanami.root.join("apps", "web", "templates", name).to_s
      ERB.new(::File.read(path)).result(context)
    end

  end
end
