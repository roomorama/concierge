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
        error_message.empty?
      end

      def error_message
        errors = []
        if description.nil?
          errors << "Description not found"
        elsif description.images.empty?
          errors << "Invalid description: images list is empty"
        end
        errors.join("\n")
      end
    end
  end
end
