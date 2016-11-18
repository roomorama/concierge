module Waytostay::Properties::Localiser

  def self.translate(key, values)
    @@translations ||= load_translations
    template = @@translations.get(key) || ""
    return template % values
  end

  def self.load_translations
    t = {}
    Dir['./lib/concierge/suppliers/waytostay/properties/locales/*.yml'].each do |file|
      t.merge! YAML.load_file(file)
    end
   Concierge::SafeAccessHash.new(t)
  end
end
