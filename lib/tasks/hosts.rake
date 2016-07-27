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
end
