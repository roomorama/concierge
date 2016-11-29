module Web::Controllers::Overwrites
  class Create
    include Web::Action

    def call(params)
      attributes = { host_id: params[:host_id] }.merge params["overwrite"]
      creation = Concierge::Flows::OverwriteCreation.new(attributes)

      validation = creation.validate
      if validation.success?
        create_result = creation.perform
        flash[:error] = create_result.error.data unless create_result.success?
      else
        flash[:error] = validation.error.data
      end

      redirect_to routes.supplier_path(params[:supplier_id])
    end
  end
end
