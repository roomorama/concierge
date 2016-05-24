namespace :suppliers do
  desc "Loads the suppliers.yml file into the database"
  task load: :environment do
    puts "Suppliers: #{SupplierRepository.all.size}"
  end
end
