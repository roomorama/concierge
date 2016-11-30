module Roomorama
  module CancellationPolicy
    FLEXIBLE     = 'flexible'.freeze
    MODERATE     = 'moderate'.freeze
    FIRM         = 'firm'.freeze
    STRICT       = 'strict'.freeze
    SUPER_STRICT = 'super_strict'.freeze
    NO_REFUND    = 'no_refund'.freeze

    def self.all
      [FLEXIBLE, MODERATE, FIRM, STRICT, SUPER_STRICT, NO_REFUND]
    end
  end
end
