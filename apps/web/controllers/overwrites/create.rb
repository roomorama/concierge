module Web::Controllers::Overwrites
  class Create
    include Web::Action

    def call(params)
      attributes = { host_id: params[:host_id] }.merge params["overwrite"]
      management = Concierge::Flows::OverwriteManagement.new(attributes)

      validation = management.validate
      if validation.success?
        create_result = management.create
        if create_result.success?
          flash[:notice] = "Successfully created"
        else
          flash[:error] = create_result.error.data
        end
      else
        flash[:error] = validation.error.data
      end

      redirect_to routes.supplier_host_overwrites_path(params[:supplier_id], params[:host_id])
    end
  end
end
