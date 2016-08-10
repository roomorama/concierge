require "yaml"

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

  desc "Create hosts as declared in yml"
  task :create_from_yaml, [:roomorama_access_token] => :environment do |t, args|
    path = Hanami.root.join("config", "hosts.yml").to_s

    hosts_by_supplier = YAML.load_file(path)

    hosts_by_supplier.each do |supplier_name, hosts_config|
      supplier = Supplier.named(supplier_name)
      unless supplier
        puts "Cannot find supplier: #{supplier_name}"
        next
      end

      hosts_config.each do |host_identifier, config|
        res = Concierge::Flows::RemoteHostCreation.new(identifier: host_identifier,
                                                 config: config,
                                                 supplier: supplier,
                                                 access_token: args[:roomorama_access_token]
                                                ).perform
        if res.success?
          puts "Created #{supplier_name};#{host_identifier}"
        else
          puts "Error : #{res.error.code} #{res.error.data}"
        end
      end
    end
  end
end

