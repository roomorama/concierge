namespace :properties do
  desc "Patch amenities on roomorama"
  task :patch_amenities, [:refs] => :environment do |t, args|
    args[:refs].each do |ref|
      diff = Roomorama::Diff.new(ref)
      property = PropertyRepository.identified_by(ref).first
      unless property
        puts "Property not found in concierge db: #{ref}"
        next
      end
      host = HostRepository.find(property.host_id)

      diff.amenities = property.data.get("amenities")
      operation = Roomorama::Client::Operations.diff(diff)
      result = Workers::OperationRunner.new(host).perform(operation)
      unless result.success?
        puts "Unsuccessful: #{result}"
      end
    end
  end
end
