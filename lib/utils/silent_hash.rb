module SilentDig
  def silent_dig(key, *rest)
    if value = (self[key] rescue nil)
      if rest.empty?
        value
      elsif value.respond_to?(:silent_dig)
        value.silent_dig(*rest)
      end
    end
  end
end

class Hash
  include SilentDig
end

