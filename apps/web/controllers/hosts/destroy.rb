module Web::Controllers::Hosts
  class Destroy
    include Web::Action

    params do
      param :supplier_id, type: String, presence: true
      param :id,          type: Integer, presence: true
    end

    def call(params)
      if params.valid?
        result = host_deletion.call

        if result.success?
          flash[:notice] = "Host was successfully deleted"
        else
          announce_error(result)
          flash[:error] = "Host deletion unsuccessful: #{result.error.code}; See External Errors for details."
        end
      else
        flash[:error] = "Parameters validation error"
      end

      redirect_to routes.supplier_path(params[:supplier_id])
    end

    private

    def announce_error(result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   "host_deletion",
        supplier:    supplier.name,
        code:        result.error.code,
        description: result.error.data,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    def host_deletion
      Concierge::Flows::HostDeletion.new(host)
    end

    def host
      HostRepository.find(params[:id])
    end

    def supplier
      SupplierRepository.find(params[:supplier_id])
    end
  end
end
