module JTB
  module Entities
    class State
      include Hanami::Entity

      attributes :prefix, :file_name
    end
  end
end
