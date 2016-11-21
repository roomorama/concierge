require "erb"

module Concierge

  # +Concierge::SupplierConfig+
  #
  # This class manages suppliers' configs.
  # Config is stored in the +config/suppliers.yml+ file
  #
  # Usage
  #
  #   Concierge::SupplierConfig.for("Supplier")
  #   # => Hash
  class SupplierConfig
    REQUIRED_FIELDS = ["path", "controller", "workers"]
    # one of this field should be configured for each worker
    WORKER_FIELDS = ["every", "absence", "aggregated"]

    # +Concierge::SupplierConfig::MissingFieldError+
    #
    # This is raised when validating suppliers and one of the required fields
    # is either not defined or empty for some supplier.
    class MissingFieldError < StandardError
      def initialize(supplier, missing_field)
        super(%<Missing field "#{missing_field}" for supplier "#{supplier}">)
      end
    end

    # +Concierge::SupplierConfig::InvalidWorkerError+
    #
    # This is raised when validating suppliers' workers
    class InvalidWorkerError < StandardError
    end

    class << self

      # Parses the content of the suppliers file and caches it at the class level to avoid
      # keeping the same content on every instance.
      def data
        @_data ||= read(config_path)
      end

      # Hard @_data reread
      def reload!(path = nil)
        path = config_path unless path
        @_data = read(path)
      end

      def for(name)
        data[name]
      end

      def suppliers
        data.keys
      end

      # Makes sure that required fields defined for each supplier
      #
      # Usage:
      #
      #   SupplierConfig.validate_suppliers!
      #
      # This will raise exceptions in case the required supplier fields are
      # not defined or empty. This ensures that when the application boots,
      # all required suppliers are properly set up.
      def validate_suppliers!
        data.each do |supplier_name, config|
          REQUIRED_FIELDS.each do |field|
            result = config[field]
            raise MissingFieldError.new(supplier_name, field) if (result.nil? || result.to_s.empty?)
          end
          
          validate_workers!(supplier_name, config["workers"])
        end
      end

      private

      def config_path
        Hanami.root.join("config", "suppliers.yml").to_s
      end

      def read(path)
        configs = ERB.new(File.read(path))
        YAML.load(configs.result) || {} # if the file is empty, +load+ returns +false+
      end

      def validate_workers!(supplier_name, definitions)
        definitions.each do |type, config|
          raise InvalidWorkerError.new(%<Invalid worker type "#{type}" for supplier "#{supplier_name}">) unless BackgroundWorker::TYPES.include?(type)
          raise InvalidWorkerError.new(%<Error "#{type}" worker definition for supplier "#{supplier_name}". Empty config.>) if config.to_s.empty?

          absence    = config.key?("absence")
          interval   = config.key?("every")
          aggregated = config.key?("aggregated")

          unless absence || interval
            raise InvalidWorkerError.new(%<Error "#{type}" worker definition for supplier "#{supplier_name}". It should contain "absence" or "every" field>)
          end
          if absence && (interval || aggregated)
            raise InvalidWorkerError.new(%<Error "#{type}" worker definition for supplier "#{supplier_name}". "absence" worker should not contain any other configs>)
          end
        end
      end
    end
  end
end
