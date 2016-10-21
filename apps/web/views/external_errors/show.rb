require "rexml/document"
require "rexml/formatters/pretty"

module Web::Views::ExternalErrors

  # +Web::Views::ExternalErrors::Show+
  #
  # The external errors show page displays the error time line, as collected
  # by the API context, wrapped by +Concierge::Context+.
  #
  # Each event type, under +Concierge::Context+ has its own presenter, allowing
  # a detailed timeline of the error occurrence to be presented, helping the
  # debugging process.
  class Show
    include Web::View
    include Concierge::JSON

    # event types in the +context+ column of the error should be one of the
    # types listed in this constant. As new events are supported and new
    # partials for presentation built, this list should evolve to reflect that.
    SUPPORTED_TYPES = [
      Concierge::Context::CacheHit::CONTEXT_TYPE,
      Concierge::Context::CacheMiss::CONTEXT_TYPE,
      Concierge::Context::CacheInvalidation::CONTEXT_TYPE,
      Concierge::Context::IncomingRequest::CONTEXT_TYPE,
      Concierge::Context::JSONParsingError::CONTEXT_TYPE,
      Concierge::Context::ResponseMismatch::CONTEXT_TYPE,
      Concierge::Context::Message::CONTEXT_TYPE,
      Concierge::Context::NetworkFailure::CONTEXT_TYPE,
      Concierge::Context::NetworkRequest::CONTEXT_TYPE,
      Concierge::Context::NetworkResponse::CONTEXT_TYPE,
      Concierge::Context::SOAPRequest::CONTEXT_TYPE,
      Concierge::Context::SOAPResponse::CONTEXT_TYPE,
      Concierge::Context::SyncProcess::CONTEXT_TYPE,
      Concierge::Context::MissingBasicData::CONTEXT_TYPE,
      Concierge::Context::TokenRequest::CONTEXT_TYPE,
      Concierge::Context::TokenReceived::CONTEXT_TYPE
    ]

    # content-type declarations, as specified by HTTP headers.
    JSON        = %r(json)
    XML         = %r(xml)
    PLAIN_TEXT  = %r(plain)

    # checks if the current +error+ is a legacy error report. Legacy errors
    # happened before the introduction of +Concierge::Context+ and therefore
    # lack valid +context+ data.
    def legacy?
      concierge_version.to_s.empty?
    end

    # extracts the version of Concierge that was running at the time of the error.
    def concierge_version
      context[:version]
    end

    # extracts the host (server) that picked up the request when the error
    # happened.
    def concierge_host
      context[:host]
    end

    # returns a list of events for the +error+ being presented. The +context+
    # column is of JSON type, where the +events+ field contains a list of
    # events that were registered during the request handling cycle.
    #
    # Each event on the list is a hash wrapped with +Concierge::SafeAccessHash+.
    def events
      @events ||= Array(context[:events]).reverse.map { |event| Concierge::SafeAccessHash.new(event) }
    end

    # Determines the partial to be rendered for a given +event+, expected to
    # be an instance of +Concierge::SafeAccessHash+. If the event has a +type+
    # field matching one of the elements in the +SUPPORTED_TYPES+ list, then
    # that partial is rendered. Otherwise, the +unrecognised_event+ partial
    # is rendered, which should inform the user about the unexpected data.
    def partial_path(event)
      if SUPPORTED_TYPES.include?(event[:type])
        name = event[:type]
      else
        name = "unrecognised_event"
      end

      # since +name+ can only be in previously known values, there is no runtime
      # harm of using +_raw+ here.
      _raw ["external_errors/", "events/", name].join
    end

    # determines the CSS classes that should be applied in order to provide
    # syntax highlight for a given content type. Currently, only JSON and
    # XML syntax highlighting are supported.
    def syntax_highlight_class(content_type)
      case content_type
      when JSON
        "highlight json"
      when XML
        "highlight xml"
      end
    end

    # tries to pretty print +content+ given that it is of +content_type+.
    # Supported types are only +PLAIN_TEXT+, +XML+ and +JSON+.
    def pretty_print(content, content_type)
      case content_type
      when PLAIN_TEXT
        monospace(h(content))

      when JSON
        # first, checks that the content is a valid JSON string. In case it is
        # not, the content is returned as is.
        parsed = json_decode(content)
        return content unless parsed.success?

        # uses the +pretty+ and +indent+ options provided by +Yajl::Encoder+ to
        # format the parsed JSON. Generates two line breaks per line (not for empty arrays)
        # to make the final content more readable.
        compact_empty_arrays(
          double_line_breaks Yajl::Encoder.encode(parsed.value, pretty: true, indent: " " * 2)
        )

      when XML
        # pretty printing XML is not reliable using Ruby's default +REXML+ library.
        # Specially since most of the XML presented by Concierge will be resulting
        # from SOAP requests/responses. Such XML payloads typically contain
        # namespaces that are not recognised by the parser which in turn refuses to
        # pretty print the XML content.
        #
        # Therefore, adopt a best effort approach of trying to parse the content
        # using that library and, if not possible, fallback to just doubling the
        # line breaks for improved readability.
        pretty_print_xml(content) || double_line_breaks(content)

      else
        # if the content-type is not supported, return the +content+ given
        # without modification.
        content
      end
    end

    # Searches for occurrences of text wrapped in backticks, and rewrite the string
    # to include +code+ tags, so that they are property formatted when displaying
    # a message
    #
    # Example
    #
    #   str = "Check the `errors` field, inside `response`, for details."
    #   monospace(str) # =>
    #     "Check the <code>errors</code> field, inside <code>response</code>, for details."
    def monospace(str)
      _raw str.gsub(/`([^`]*)`/, '<code>\1</code>')
    end

    # formats the timestamp of format "2016-05-25 19:32:51 +0800"
    # to a format which includes the timezone, for clarity.
    def format_timestamp(timestamp)
      Time.parse(timestamp).strftime("%T (%z)")
    end

    # Make +Hanami::Helpers::EscapeHelper#escape_html+ public
    # and available from templates
    public :h

    private

    def pretty_print_xml(content)
      doc = REXML::Document.new(content)

      indent = 2
      formatter = REXML::Formatters::Pretty.new(indent)
      formatter.compact = 2

      # the +formatter+ expects an +IO+ like object
      output = StringIO.new

      formatter.write(doc, output)

      output.rewind
      double_line_breaks output.read
    rescue REXML::ParseException
      # if the parsing of the XML fails, return +nil+ and fallback
      # to doubling line breaks
    end

    def context
      error.context
    end

    def double_line_breaks(str)
      str.gsub("\n", "\n\n")
    end

    def compact_empty_arrays(str)
      str.gsub(/\[\s*\]/, '[]')
    end
  end
end
