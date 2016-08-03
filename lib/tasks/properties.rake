namespace :properties do
  desc "Patch amenities on roomorama"
  task :patch_amenities, [:refs] => :environment do |t, args|
    args[:refs].each_with_index do |ref, index|
      diff = Roomorama::Diff.new(ref)
      property = PropertyRepository.identified_by(ref).first
      unless property
        puts "##{index} Unsuccessful: property not found in Concierge"
        next
      end
      host = HostRepository.find(property.host_id)

      diff.amenities = property.data.get("amenities")
      operation = Roomorama::Client::Operations.diff(diff)
      roomorama_property = Roomorama::Property.load(property.data.merge(identifier: ref))
      unless roomorama_property.success?
        puts "##{index} Unsuccessful: #{roomorama_property.error.code} #{roomorama_property.error.data}"
        next
      end
      result = Workers::OperationRunner.new(host).perform(operation, roomorama_property.value)
      if result.success?
        puts "##{index} Successful"
      else
        puts "##{index} Unsuccessful: #{result.error.code} #{result.error.data}"
      end
    end
  end
end
