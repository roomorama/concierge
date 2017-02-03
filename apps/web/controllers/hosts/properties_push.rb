module Web::Controllers::Hosts
  class PropertiesPush
    include Web::Action
    def call(params)
      Concierge::Flows::PropertyPush.new(host).call
      redirect_to routes.supplier_host_path(supplier_id: params[:supplier_id],
                                            id: params[:id])
    end

    private

    def host
      @host ||= HostRepository.find params[:id]
    end
  end
end

