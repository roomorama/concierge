module Web::Controllers::Hosts
  class New
    include Web::Action

    expose :supplier

    def call(params)
      @supplier = SupplierRepository.find(params[:supplier_id])
    end
  end
end
