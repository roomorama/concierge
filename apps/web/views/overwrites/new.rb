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
  end
end
