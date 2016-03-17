require "yaml"

module Concierge

  # +Concierge::Environment+
  #
  # Manages environment variables required by Concierge, making sure that all
  # of them are defined when the application boots, avoiding unexpected results
  # on runtime.
  #
  # Usage
  #
  #   Concierge::Environment.verify!
  #   # => true
  #
  # By default, the list of required environment variables is located at
  # +config/environment_variables.yml+. If one of the variables declared in
  # that file is not defined or is empty, the +verify!+ method will raise
  # an exception, halting the boot process.
  class Environment

    class UndefinedVariableError < StandardError
      def initialize(name)
        super("Expected environment variable #{name} to be defined.")
      end
    end

    # convenience method for the default behaviour.
    def self.verify!
      new.verify!
    end

    attr_reader :required_variables_path

    # +required_variables_path+ is the path to the YML file containing
    # the list of required environment variables.
    def initialize(required_variables_path = default_required_variables_path)
      @required_variables_path = required_variables_path
    end

    # Checks that all required environment variables are defined and
    # non-empty. Returns +true+ on success or raises an exception
    # otherwise (+Concierge::Environment::UndefinedVariableError+).
    def verify!
      required_variables.each do |name|
        unless present?(name)
          raise UndefinedVariableError.new(name)
        end
      end

      true
    end

    private

    def present?(name)
      val = ENV[name]
      val && !val.to_s.empty?
    end

    def required_variables
      @required_variables ||= YAML.load_file(required_variables_path)
    end

    def default_required_variables_path
      Hanami.root.join("config/environment_variables.yml").to_s
    end

  end
end
