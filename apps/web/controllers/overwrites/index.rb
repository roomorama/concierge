module Web::Controllers::Overwrites
  class Index
    include Web::Action

    expose :supplier_id
    expose :host_id
    expose :username
    expose :overwrites

    def call(params)
      @supplier_id = params[:supplier_id]
      @host_id = params[:host_id]
      @overwrites = OverwriteRepository.for_host_id(params[:host_id])
      @username = HostRepository.find(params[:host_id]).username
    end
  end
end
