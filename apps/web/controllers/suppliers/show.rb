require_relative "../internal_error"

module Web::Controllers::Suppliers
  class Show
    include Web::Action
    include Web::Controllers::InternalError

    params do
      param :id, type: Integer, presence: true
    end

    expose :supplier, :hosts

    def call(params)
      @supplier = SupplierRepository.find(params[:id])

      if @supplier
        @hosts = HostRepository.from_supplier(@supplier)
      end

      unless @supplier
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
