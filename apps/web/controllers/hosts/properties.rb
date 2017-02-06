module Web::Controllers::Hosts
  class Properties
    include Web::Action

    expose :properties

    def call(params)
      @properties = PropertyRepository.from_host(host).all
    end

    def host
      HostRepository.find params[:id]
    end
  end
end

