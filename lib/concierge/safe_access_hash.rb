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
        result = result[k]
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

    # Returns true if any keys are missing in the hash
    # +keys+ should be an array of +string+
    # This will yield each of the missing keys,
    # so a method block can be passed to handle it.
    #
    def missing_any?(keys)
      # Using `all?` to iterate through all keys
      all_present = keys.all? { |key|
        if self.get(key).nil?
          yield key
          false
        else
          true
        end
      }
      !all_present
    end
  end

end
