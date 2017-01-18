module Workers::Suppliers::Kigo
  # +Workers::Suppliers::Kigo::Availabilities+
  #
  # this class responsible for handling differences identifiers
  # and calling process +Workers::Suppliers::Kigo::Property+ only for each
  # updated property
  #
  class Metadata

    attr_reader :supplier, :property_content_diff_id

    def initialize(supplier, args = {})
      @supplier                 = supplier
      @property_content_diff_id = args[:property_content_diff_id]
    end

    def perform
      property_content_diff = new_context do
        importer.fetch_property_content_diff(property_content_diff_id)
      end
      unless property_content_diff.success?
        announce_error('Failed to perform `#fetch_property_content_diff` operation', prices_diff)
        return initial_args_result
      end

      identifiers = property_content_diff.value['PROP_ID']

      identifiers.each { |property_id| update_property(property_id) }

      Result.new({ property_content_diff_id: property_content_diff.value['DIFF_ID'] })
    end

    private

    def update_property(property_identifier)
      Workers::Suppliers::Kigo::Property.new(property_identifier).perform
    end

    def new_context
      Concierge.context = Concierge::Context.new(type: "batch")

      message = Concierge::Context::Message.new(
        label:     'Aggregated Sync',
        message:   "Started aggregated metadata sync for `#{supplier}`",
        backtrace: caller
      )

      Concierge.context.augment(message)
      yield
    end

    def importer
      @importer ||= Kigo::Importer.new(credentials, request_handler)
    end

    def request_handler
      Kigo::Request.new(credentials, timeout: 40)
    end

    def credentials
      Concierge::Credentials.for(Kigo::Client::SUPPLIER_NAME)
    end

    def announce_error(message, result)
      message = {
        label:     'Synchronisation Failure',
        message:   message,
        backtrace: caller
      }
      context = Concierge::Context::Message.new(message)
      Concierge.context.augment(context)

      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   'sync',
        supplier:    supplier.name,
        code:        result.error.code,
        description: result.error.data,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    def initial_args_result
      Result.new({property_content_diff_id: property_content_diff_id})
    end
  end
end

Concierge::Announcer.on("metadata.Kigo") do |supplier, args|
  Workers::Suppliers::Kigo::Metadata.new(supplier, args).perform
end
