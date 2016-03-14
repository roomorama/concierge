Hanami::Model.migration do
  change do
    create_table :cache_entries do
      # no need for an artificial, incremental ID for this table. Cached entries
      # are indexed by a given key and that should be the primary key for the table.
      column :key, String, size: 1024, null: false, primary_key: true

      column :value,      String, text: true, null: false
      column :updated_at, Time,               null: false
    end
  end
end
