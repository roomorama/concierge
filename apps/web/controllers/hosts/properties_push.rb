module Web::Controllers::Hosts
  class PropertiesPush
    include Web::Action
    def call(params)
      Concierge::Flows::PropertyPushJobEnqueue.new(property_ids).call
      flash[:notice] = "Properties push process queued. Please check External Error for any errors."
      redirect_to routes.supplier_host_path(supplier_id: params[:supplier_id],
                                            id: params[:id])
    end

    private

    def property_ids
      PropertyRepository.from_host(host).collect(&:id)
    end

    def host
      @host ||= HostRepository.find params[:id]
    end
  end
end

