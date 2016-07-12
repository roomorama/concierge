module Concierge
  # +Concierge::SafeAccessHash+
  #
  # This class helps to manage deep nested hashes
  # It makes flexible usage with indifferent access and quick fetching with composite keys
  # and avoiding NoMethodError for deep nested objects
  #
  # Example:
  #
  #   wise_hash = Concierge::SafeAccessHash.new({ name: 'Alex', foo: { bar: { '@strange_key' => 20 } } })
  #   wise_hash[:name]  # => "Alex"
  #   wise_hash['name'] # => "Alex"
  #   wise_hash.get('foo.bar.@strange_key') # => 20
  #   wise_hash.get('foo.bar.unknown') # => nil
  class SafeAccessHash
    GET_SEPARATOR = '.'

    def initialize(hash)
      @hash = Hanami::Utils::Hash.new(hash).deep_dup.stringify!
    end

    def [](key)
      value = @hash[key.to_s]
      value = SafeAccessHash.new(value) if value.is_a?(Hanami::Utils::Hash)
      value
    end

    def get(key)
      key, *keys = key.to_s.split(GET_SEPARATOR)
      result     = self[key]

      Array(keys).each do |k|
        break if result.nil?
        result = result.is_a?(SafeAccessHash) ? result[k] : nil
      end
      result = SafeAccessHash.new(result) if result.is_a?(Hanami::Utils::Hash)
      result
    end

    def ==(other)
      to_h == other.to_h
    end

    def to_h
      @hash.to_h
    end

    def to_s
      to_h.to_s
    end

    def merge(other)
      Concierge::SafeAccessHash.new(@hash.merge(other))
    end

    # Returns array of keys that do not have value in the hash
    # Given +required_keys+ should be an array of +string+
    #
    def missing_keys_from(required_keys)
      required_keys.select{ |k| self.get(k).nil? }
    end
  end

end
