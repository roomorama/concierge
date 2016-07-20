module Web::Support
  module Formatters

    # +Web::Support::Formatters::Number+
    #
    # This class holds a utility methods for converting numbers for presentation.
    class Number

      # converts a number to its more human-readable version including commas
      # to separate thousands.
      #
      # Example:
      #
      #   formatter = Web::Support::Formatters::Number.new
      #   formatter.present(27840) # => "27,840"
      def present(n)
        n.               # 27840
          to_s.          # "27840"
          chars.         # ["2", "7", "8", "4", "0"]
          reverse.       # ["0", "4", "8", "7", "2"]
          each_slice(3). # Enumerator
          to_a.          # [["0", "4", "8"], ["7", "2"]]
          map(&:join).   # ["048", "72"]
          join(",").     # "048,72"
          reverse        # "27,840"
      end

    end
  end

end
