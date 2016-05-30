Hanami::Model.migration do

  # updates existing +external_errors+ entries to the format expected
  # by the +context+ column. For those cases, all that is done is rendering
  # a best-effort view, including the existing message.
  #
  # This allows existing errors to be presented according to the
  # timeline presenters.
  up do
    errors = ExternalErrorRepository.send(:query) do
      where("message IS NOT NULL AND message != ''")
    end.to_a

    errors.each do |error|
      context = Concierge::Context.new
      message = Concierge::Context::Message.new(
        label: "Generic Error",
        message: "This error happened before the timeline feature was released. " +
          "The original error message was:\n\n#{error.message}",
        backtrace: []
      )

      context.augment(message)
      attributes = context.to_h

      # deletes Concierge version and host from the payload, since these fields
      # would be inaccurate. Their abscence indicates to the presenter that
      # this is a legacy error.
      attributes.delete(:version)
      attributes.delete(:host)

      error.context = attributes

      ExternalErrorRepository.update(error)
    end
  end

  down do
    # no change when rolling back this migration
  end
end
