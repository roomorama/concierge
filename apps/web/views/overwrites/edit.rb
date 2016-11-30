module Web::Views::Overwrites
  class Edit
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
      :patch
    end

    def form_path
      routes.supplier_host_overwrite_path(supplier_id, host_id, params[:id])
    end
  end
end
