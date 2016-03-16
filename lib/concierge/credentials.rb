require "erb"

module Concierge

  # +Concierge::Credentials+
  #
  # This class manages credentials for interacting with protected supplier APIs.
  # Credentials are stored in the +config/credentials+ directory, in YML files
  # named after the running environment. Therefore, in a +staging+, credentials
  # will be loaded from a +config/credentials/staging.yml+ file.
  #
  # See YML files under that directory to understand how credentials are stored.
  # Note that production credentials should *always* be stored in environment
  # variables.
  #
  # Usage
  #
  #   Concierge::Credentials.for("Supplier")
  #   # => Struct(username="roomorama" password"p4ssw0rd")
  class Credentials

    # +Concierge::Credentials::MissingSupplierError+
    #
    # This is raised when validating credentials and there is no information found
    # for a given supplier.
    class MissingSupplierError < StandardError
      def initialize(supplier)
        super(%<No credential information for supplier "#{supplier}">)
      end
    end

    # +Concierge::Credentials::MissingCredentialError+
    #
    # This is raised when validating credentials and one of the required credentials
    # is either not defined or empty.
    class MissingCredentialError < StandardError
      def initialize(supplier, missing_credential)
        super(%<Missing credential "#{missing_credential}" for supplier #{supplier}>)
      end
    end

    class << self

      # Parses the content of the credentials file and caches it at the class level to avoid
      # keeping the same content on every instance.
      def data
        @_data ||= begin
          config_path = Hanami.root.join("config", "credentials", [Hanami.env, "yml"].join("."))
          configs = ERB.new(File.read(config_path))

          YAML.load(configs.result)
        end
      end

      def for(name)
        credentials = data[name.downcase]
        Struct.new(*credentials.keys.map(&:to_sym)).new(*credentials.values)
      end

      # Makes sure that the given set of credentials exist when the application boots.
      #
      # Usage:
      #
      #   Credentials.validate_credentials!({
      #     "supplier"      => %w(username password),
      #     "othersupplier" => %w(access_token)
      #   })
      #
      # This will raise exceptions in case the required credentials are
      # not defined or empty. This ensures that when the application boots,
      # all required credentials are properly set up.
      def validate_credentials!(credentials)
        credentials.each do |supplier, required_credentials|
          supplier_credentials = data[supplier.to_s]

          unless supplier_credentials
            raise MissingSupplierError.new(supplier)
          end

          required_credentials.each do |credential|
            if supplier_credentials[credential].nil? || supplier_credentials[credential].empty?
              raise MissingCredentialError.new(supplier, credential)
            end
          end
        end
      end
    end

  end
end
