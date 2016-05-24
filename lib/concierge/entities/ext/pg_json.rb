require "sequel"

# load PostgreSQL specific extensions to the Sequel ORM.
Sequel.extension(:pg_array, :pg_json)

module Concierge

  # Concierge::PGJSON+
  #
  # By default, +hanami-model+ is not able to natively work with PostgreSQL's
  # +json+ data type. Therefore, it is necessary to write a custom data
  # coercer so that Hanami is able to serialize the data to the database
  # and load it back to the application.
  #
  # This class implements the protocol expected by Hanami data coercers,
  # providing +dump+ and +load+ methods. It leverages the +Sequel.pg_json+
  # method to transform a regular hash into a +json+ representation,
  # as well as +Concierge::SafeAccessHash+ when loading data from the
  # database.
  class PGJSON < Hanami::Model::Coercer

    # value - if present, expected to be a Ruby Hash.
    def self.dump(value)
      Sequel.pg_json(value)
    end

    def self.load(value)
      unless value.nil?
        Concierge::SafeAccessHash.new(value)
      end
    end

  end
end
