module Web::Controllers::Hosts
  class New
    include Web::Action

    expose :supplier
    expose :host

    def call(params)
      @supplier = SupplierRepository.find(params[:supplier_id])
      @host = Host.new
    end
  end
end
