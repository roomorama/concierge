class Workers::Processor
  class PropertiesPush
    attr_reader :ids

    def initialize(ids)
      @ids = ids
    end

    def run
      results = ids.collect { |id| publish(id) }
      results.each do |r|
        announce(r.error) unless r.success?
      end
      Result.new(true)
    end

    private

    def publish(id)
      property = PropertyRepository.find id
      host = HostRepository.find property.host_id
      roomorama_property_load = load(property)
      return roomorama_property_load unless roomorama_property_load.success?

      op = Roomorama::Client::Operations.publish(roomorama_property_load.value, { should_persist: false })
      ::Workers::OperationRunner.new(host).perform(op, roomorama_property_load.value)
    end

    def load(property)
      Roomorama::Property.load(property.data)
    end

    def announce(error)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   "sync",
        supplier:    error_source_name,
        code:        error.code,
        description: error.data,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    # Because external errors reported here
    # are only caused by roomorama api failures
    #
    def error_source_name
      "roomorama"
    end
  end
end
