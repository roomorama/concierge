module Web::Controllers::Overwrites
  class Update
    include Web::Action

    def call(params)
      attributes = { host_id: params[:host_id], id: params[:id] }.merge params["overwrite"]
      management = Concierge::Flows::OverwriteManagement.new(attributes)

      validation = management.validate
      if validation.success?
        update_result = management.update
        if update_result.success?
          flash[:notice] = "Successfully updated"
        else
          flash[:error] = update_result.error.data
        end
      else
        flash[:error] = validation.error.data
      end

      redirect_to routes.supplier_host_overwrites_path(params[:supplier_id], params[:host_id])
    end
  end
end
