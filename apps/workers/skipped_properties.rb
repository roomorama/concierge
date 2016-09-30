module Workers
  # +Workers::SkippedProperties+
  #
  # Encapsulates the logic of work with properties skipped during sync process
  #
  # Usage
  #
  #   skipped_properties = SkippedProperties.new
  #   skipped_properties.add('prop1', 'On request property')
  #
  #   skipped_properties.skipped?('prop1') # => true
  #   skipped_properties.skipped?('prop2') # => false
  #   skipped_properties.to_a # [{'reason' => 'On request property', 'ids' => ['prop1']}]
  class SkippedProperties

    def initialize
      @skipped = Hash.new { |hsh, key| hsh[key] = [] }
      @identifiers = Set.new
    end

    def add(identifier, reason)
      @skipped[reason] << identifier
      @identifiers << identifier
    end

    def skipped?(identifier)
      @identifiers.include?(identifier)
    end

    def to_a
      @skipped.map do |msg, ids|
        {
          'reason' => msg,
          'ids' => ids
        }
      end
    end
  end
end