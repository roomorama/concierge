namespace :properties do
  desc "Patch amenities on roomorama"
  task :patch_amenities, [:refs] => :environment do |t, args|
    args[:refs].each do |ref|
      diff = Roomorama::Diff.new(refs)
      property = PropertyRepository.identified_by(ref).first
      unless property
        puts "Property not found in concierge db: #{ref}"
        next
      end
      diff.amenities = property.data.get("amenities")
      operation = Roomorama::Client::Operations.diff(diff)
      result = Workers::OperationRunner.new(host).perform(operation, *args)
      unless result.success?
        puts "Unsuccessful: #{result}"
      end
    end
  end
end
