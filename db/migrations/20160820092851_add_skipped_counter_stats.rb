Hanami::Model.migration do
  up do
    SyncProcessRepository.of_type('metadata').each do |sync_record|
      sync_record.stats = sync_record.stats.to_h.merge({properties_skipped: 0})
      SyncProcessRepository.update(sync_record)
    end
  end

  down do
    SyncProcessRepository.of_type('metadata').each do |sync_record|
      stats = sync_record.stats.to_h
      stats.delete('properties_skipped')
      sync_record.stats = stats
      SyncProcessRepository.update(sync_record)
    end
  end
end
