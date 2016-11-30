module Web::Controllers::Overwrites
  class New
    include Web::Action

    expose :overwrite

    def call(params)
      @overwrite  = Overwrite.new
    end
  end
end
