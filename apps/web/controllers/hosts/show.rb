module Web::Controllers::Hosts
  class Show
    include Web::Action

    expose :supplier
    expose :host

    def call(params)
      @supplier = SupplierRepository.find(params[:supplier_id])
      @host = HostRepository.find(params[:id])
    end
  end
end

