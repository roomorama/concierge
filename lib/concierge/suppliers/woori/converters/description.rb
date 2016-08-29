module Woori
  module Converters
    # +Woori::Converters::Description+
    #
    # This class is responsible for converting original description to
    # description which includes additional amenities.
    #
    # Including additional amenities to the description is needed because
    # +Woori+ has lots of facility services which are not supported by
    # Roomorama API and will not be shown in property/unit pages.
    #
    # So, in case if original description is:
    #
    #   "Test description"
    #
    # This class adds additional amenities info like this:
    #
    #   "Test description. Additional amenities: foo, bar"
    class Description
      attr_reader :original_description, :amenities_converter

      def initialize(original_description, amenities_converter)
        @original_description = original_description
        @amenities_converter = amenities_converter
      end

      def convert
        text = original_description.to_s.strip.gsub(/\.\z/, "")
        text_amenities = formatted_additional_amenities

        description_parts = [text, text_amenities].reject(&:empty?)

        if description_parts.any?
          description_parts.join('. ')
        end
      end

      private
      def formatted_additional_amenities
        if additional_amenities.any?
          text = 'Additional amenities: '
          text += additional_amenities.join(', ')
        else
          ""
        end
      end

      def additional_amenities
        amenities_converter.select_not_supported_amenities
      end
    end
  end
end
