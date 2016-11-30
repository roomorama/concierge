module Web::Controllers::Overwrites
  class Edit
    include Web::Action

    expose :overwrite

    def call(params)
      @overwrite   = OverwriteRepository.find params[:id]
    end
  end
end
