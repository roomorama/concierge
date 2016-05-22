require "sequel"

# load PostgreSQL specific extensions to the Sequel ORM.
Sequel.extension(:pg_hstore, :pg_hstore_ops)

module Concierge

  # Concierge::HStore+
  #
  # By default, +hanami-model+ is not able to natively work with PostgreSQL's
  # +hstore+ data type. Therefore, it is necessary to write a custom data
  # coercer so that Hanami is able to serialize the data to the database
  # and load it back to the application.
  #
  # This class implements the protocol expected by Hanami data coercers,
  # providing +dump+ and +load+ methods. It leverages the +Sequel.hstore+
  # method to transform a regular hash into an +hstore+ representation,
  # as well as +Concierge::SafeAccessHash+ when loading data from the
  # database.
  class HStore < Hanami::Model::Coercer

    # value - if present, expected to be a Ruby Hash.
    def self.dump(value)
      Sequel.hstore(value)
    end

    def self.load(value)
      unless value.nil?
        Concierge::SafeAccessHash.new(value)
      end
    end

  end
end
