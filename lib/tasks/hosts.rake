require "yaml"

# +HostCreationError+
#
# Error raised when the result of a host creation operation is not successful.
# Receives the result error code when initialized.
class HostCreationError < RuntimeError
  def initialize(code)
    super("Host creation unsuccessful: #{code}")
  end
end

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
        ).perform.tap do |result|
          raise HostCreationError.new(result.error.code) unless result.success?
        end
      end
    end
  end
end
