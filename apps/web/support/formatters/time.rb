module Web::Support
  module Formatters

    # +Web::Support::Formatters::Time+
    #
    # This class holds a utility methods for converting +Time+ for presentation.
    class Time

      # converts a time to its more human-readable, including date and time (with
      # minute precision) of the occurrence.
      #
      # Example:
      #
      #   formatter = Web::Support::Formatters::Time.new
      #   formatter.present(Time.now) # => "July 20, 2016 at 12:52"
      def present(time)
        time.strftime("%B %d, %Y at %H:%M")
      end

    end
  end

end
