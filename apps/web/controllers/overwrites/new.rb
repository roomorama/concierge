module Web::Controllers::Overwrites
  class New
    include Web::Action

    expose :supplier_id
    expose :host_id
    expose :username
    expose :overwrite

    def call(params)
      @supplier_id = params[:supplier_id]
      @host_id = params[:host_id]
      @username = HostRepository.find(@host_id).username
      @overwrite = Overwrite.new
    end
  end
end
