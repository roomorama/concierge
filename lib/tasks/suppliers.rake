require "yaml"

namespace :suppliers do
  desc "Loads the suppliers.yml file into the database"
  task load: :environment do
    total = 0
    Concierge::Suppliers.suppliers.map do |name|
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
