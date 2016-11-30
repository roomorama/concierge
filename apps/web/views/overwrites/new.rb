module Web::Views::Overwrites
  class New
    include Web::View

    def supplier_id
      params[:supplier_id]
    end

    def host_id
      params[:host_id]
    end

    def username
      HostRepository.find(host_id).username
    end

    def form_method
      :post
    end

    def form_path
      routes.supplier_host_overwrites_path(supplier_id, host_id)
    end
  end
end
