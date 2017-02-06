module Web::Controllers::Hosts
  class PropertiesPush
    include Web::Action

    params do
      param :properties_push do
        param :properties, presence: true
      end
      param :supplier_id, presence: true
      param :id,          presence: true
    end

    def call(params)
      if property_ids
        Concierge::Flows::PropertiesPushJobEnqueue.new(property_ids).call
        flash[:notice] = "Properties push process queued. Please check External Error for any errors."
      else
        flash[:error] = "No properties queued. Please try again"
      end
      redirect_to routes.supplier_host_path(supplier_id: params.get("supplier_id"),
                                            id: params.get("id"))
    end

    private

    def property_ids
      params.get("properties_push.properties")
    end

  end
end

