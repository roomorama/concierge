module Workers::Comparison

  # +Workers::Comparison::Translations+
  #
  # This class performs a comparison between two hash of translations.
  #
  # Usage
  #   original = old_roomorama_property.translations
  #   new = new_roomorama_property.translations
  #   diff = Roomorama::Diff.new(old_roomorama_property.identifier)
  #   comparison = Workers::Comparison::Translations.(original, new).apply_to(diff)
  #
  class Translations

    attr_reader :original, :new

    def initialize(original, new)
      @original = original || {}
      @new      = new || {}
    end

    def apply_to(diff)
      Roomorama::Translated::SUPPORTED_LOCALES.each do |locale|
        new_t = new[locale] || {}
        old_t = original[locale] || {}
        next if new_t.empty? && old_t.empty?
        translation = diff.public_send(locale)

        added = new_t.keys - old_t.keys
        added.each do |attr|
          translation[attr] = new_t[attr]
        end

        removed = old_t.keys - new_t.keys
        removed.each do |attr|
          translation.erase(attr)
        end

        common = old_t.keys & new_t.keys
        common.each do |attr|
          translation[attr] = new_t[attr] if new_t[attr] != old_t[attr]
        end
      end
    end
  end
end
