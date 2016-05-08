require "yaml"
require "set"

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
  # Each Concierge app (+api+ and +web+) can customize the environment
  # variables it requires upon boot time. App-specific variables
  # are defined on +apps/<app>/config/environment_variables.yml+.
  #
  # The variables defined on +config/environment_variables.yml+ are
  # required for every app.
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

    attr_reader :paths

    # paths - a list of paths to YML files containing lists of required
    # environment variables to be checked.
    def initialize(paths: [default_app_variables_path, default_concierge_variables_path])
      @paths = paths
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
      @required_variables ||= Set.new(paths.flat_map { |path| load(path) }).to_a
    end

    def load(path)
      YAML.load_file(path)
    end

    # app specific environment variables.
    def default_app_variables_path
      Hanami.root.join("apps", Concierge.app, "config", "environment_variables.yml").to_s
    end

    # variables required by Concierge, no matter which app is booting.
    def default_concierge_variables_path
      Hanami.root.join("config", "environment_variables.yml").to_s
    end

  end
end
