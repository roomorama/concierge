module Web::Controllers::Hosts
  class Create
    include Web::Action

    params do
      param :supplier_id,      type: String,  presence: true
      param :host do
        param :identifier,     type: String,  presence: true
        param :username,       type: String,  presence: true
        param :access_token,   type: String
        param :email,          type: String
        param :name,           type: String
        param :phone,          type: String
        param :payment_terms,  type: String
        param :fee_percentage, type: Integer, presence: true
      end
    end

    def call(params)
      if params.valid?
        host_creation = build_host_creation(params)
        result = host_creation.perform

        if result.success?
          flash[:notice] = "Host was successfully created"
        else
          flash[:error] = "Host creation unsuccessful: #{result.error.code}"
        end
      else
        flash[:error] = "Host parameters validation error"
      end

      redirect_to routes.supplier_path(params[:supplier_id])
    end

    private
    def build_host_creation(params)
      Concierge::Flows::HostCreation.new(
        supplier:       supplier,
        identifier:     params.get("host.identifier"),
        username:       params.get("host.username"),
        access_token:   params.get("host.access_token"),
        fee_percentage: params.get("host.fee_percentage"),
        email:          params.get("host.email"),
        phone:          params.get("host.phone"),
        name:           params.get("host.name"),
        payment_terms:  params.get("host.payment_terms"),
        config_path:    config_path
      )
    end

    def supplier
      SupplierRepository.find(params[:supplier_id])
    end

    def config_path
      Hanami.root.join("config", "suppliers.yml").to_s
    end
  end
end
