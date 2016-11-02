module Avantio
  module Validators
    # +Avantio::Validators::DescriptionValidator+
    #
    # This class responsible for description validation.
    # cases when description is invalid:
    #
    #   * images list is empty
    #
    class DescriptionValidator
      attr_reader :description

      def initialize(description)
        @description = description
      end

      def valid?
        !description.images.empty?
      end
    end
  end
end
