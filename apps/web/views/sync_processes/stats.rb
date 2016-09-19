module Web::Views::SyncProcesses
  class Stats
    include Web::View
    include Concierge::JSON

    def pretty_print_json(content)

      # uses the +pretty+ and +indent+ options provided by +Yajl::Encoder+ to
      # format the parsed JSON. Generates two line breaks per line (not for empty arrays)
      # to make the final content more readable.
      compact_empty_arrays(
        double_line_breaks Yajl::Encoder.encode(content.to_h, pretty: true, indent: " " * 2)
      )
    end

    private

    def double_line_breaks(str)
      str.gsub("\n", "\n\n")
    end

    def compact_empty_arrays(str)
      str.gsub(/\[\s*\]/, '[]')
    end
  end
end
