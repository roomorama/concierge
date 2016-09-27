module JTB
  module Entities
    class Lookup
      include Hanami::Entity

      attributes :language, :category, :id, :related_id, :name
    end
  end
end
