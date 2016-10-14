module Roomorama::Translated
  SUPPORTED_LOCALES = %i(es de zh zh_tw)

  class Translation
    TRANSLATED_FIELDS = [:title,
                         :description,
                         :terms_and_conditions,
                         :check_in_instructions,
                         :description_append]

    attr_accessor *TRANSLATED_FIELDS

    def []=(attr, value)
      if TRANSLATED_FIELDS.include?(attr)
        setter = [attr, "="].join
        public_send(setter, value)
      end
    end

    def to_h
      {
        title:                 title,
        description:           description,
        terms_and_conditions:  terms_and_conditions,
        check_in_instructions: check_in_instructions,
        description_append:    description_append,
      }.tap do |hash|
        hash.delete_if { |k, v| v.nil? }
      end
    end
  end

  def self.included(base)

    def es; @es ||= Translation.new() end
    def de; @de ||= Translation.new() end
    def zh; @zh ||= Translation.new() end
    def zh_tw; @zh_tw ||= Translation.new() end

    def translations
      hash = {}
      SUPPORTED_LOCALES.collect do |locale|
        locale_hash = self.send(locale).to_h
        hash[locale] = locale_hash unless locale_hash.empty?
      end

      hash.empty? ? nil : hash
    end
  end

end
