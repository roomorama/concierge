require "yaml"

# +SupplierLoader+
#
# Wrapper class for +Concierge::Flows::SupplierCreation+ which parses the supplier
# declaration (usually on +config/suppliers.yml+) and creates the associated records.
#
# Wraps the whole operation in a database transaction and validates that all suppliers
# contain at least one +metadata+ worker.
class SupplierLoader
  class InvalidConfigurationError < StandardError
    def initialize(path, error)
      super("Configuration file at #{path} is invalid: #{error}")
    end
  end

  attr_reader :path, :content

  def initialize(path)
    @path    = path
    @content = YAML.load_file(path)
  end

  def load!
    total = 0

    transaction do
      content.each do |supplier, definition|
        workers_definition = {
          metadata: {
            every: get(definition, "workers.metadata.every")
          }
        }

        if definition["workers"]["availabilities"]
          workers_definition.merge!(
            availabilities: {
              every: get(definition, "workers.availabilities.every")
            }
          )
        end

        result = Concierge::Flows::SupplierCreation.new(
          name:    supplier,
          workers: workers_definition
        ).perform

        unless result.success?
          raise InvalidConfigurationError(path, "Failed to persist data: check configuration")
        end
      end

      total += 1
    end

    total
  end

  private

  def get(hash, key)
    Concierge::SafeAccessHash.new(hash.to_h).get(key) ||
      (raise InvalidConfigurationError.new(path, "No key #{key} found"))
  end

  def transaction
    SupplierRepository.transaction { yield }
  end

end


namespace :suppliers do
  desc "Loads the suppliers.yml file into the database"
  task load: :environment do
    path  = Hanami.root.join("config", "suppliers.yml").to_s
    total = SupplierLoader.new(path).load!

    puts "Done. #{total} suppliers persisted."
  end
end
