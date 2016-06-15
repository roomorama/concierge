require "yaml"

namespace :suppliers do
  desc "Loads the suppliers.yml file into the database"
  task load: :environment do
    path  = Hanami.root.join("config", "suppliers.yml").to_s
    names = YAML.load_file(path) || [] # if the file is empty, +load_file+ returns +false+
    total = 0

    names.map do |name|
      existing = SupplierRepository.named(name)

      unless existing
        supplier = Supplier.new(name: name)
        SupplierRepository.create(supplier)
        total += 1
      end
    end

    puts "Done. #{total} suppliers created."
  end
end
