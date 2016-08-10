require "yaml"
require "csv"

namespace :hosts do
  desc "Updates background worker definitions for all hosts"
  task update_worker_definitions: :environment do
    path = Hanami.root.join("config", "suppliers.yml").to_s

    SupplierRepository.all.each do |supplier|
      HostRepository.from_supplier(supplier).each do |host|
        Concierge::Flows::HostCreation.new(
          supplier:       supplier,
          identifier:     host.identifier,
          username:       host.username,
          access_token:   host.access_token,
          fee_percentage: host.fee_percentage,
          config_path:    path
        ).perform
      end
    end

    puts "Done. All hosts updated."
  end

  # csv_path should point to a file with the following: identifier and fee_percentage:
  # # example.csv
  #   username,identifier,fee_percentage
  #   id1,123,7
  #   id2,124,8
  #
  desc "Create hosts as declared in yml"
  task :create_from_csv, [:csv_path, :supplier_name, :roomorama_access_token] => :environment do |t, args|
    supplier_name = args[:supplier_name]
    supplier = SupplierRepository.named(supplier_name)
    unless supplier
      puts "Cannot find supplier: #{supplier_name}"
      next
    end
    # args[:csv_path] should point to a csv of hosts for a particular supplier
    CSV.foreach(args[:csv_path], headers: true) do |row|
      res = Concierge::Flows::RemoteHostCreation.new(identifier: row["identifier"],
                                                     fee_percentage: row["fee_percentage"],
                                                     username: row["username"],
                                                     phone: "+85258087855", # default customer service number
                                                     supplier: supplier,
                                                     access_token: args[:roomorama_access_token]
                                                    ).perform
      if res.success?
        puts "Created #{supplier_name}: #{row[0]}"
      else
        puts "Error : #{res.error.code} #{res.error.data}"
      end
    end
  end
end

