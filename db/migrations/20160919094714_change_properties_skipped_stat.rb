Hanami::Model.migration do
  up do
    SyncProcessRepository.of_type('metadata').each do |sync_record|
      stats = sync_record.stats.to_h
      stats['properties_skipped'] = [
        {
          'reason' => 'Unknown reason',
          'ids' => Array.new(stats['properties_skipped'], '')
        }
      ]
      sync_record.stats = stats
      SyncProcessRepository.update(sync_record)
    end
  end

  down do
    SyncProcessRepository.of_type('metadata').each do |sync_record|
      stats = sync_record.stats.to_h
      stats['properties_skipped'] = stats['properties_skipped'].inject(0) do |res, ps|
        res + ps['ids'].length
      end
      sync_record.stats = stats
      SyncProcessRepository.update(sync_record)
    end
  end
end
