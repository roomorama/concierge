Hanami::Model.migration do
  change do
    create_table :cache_entries do
      # this table does not need an artificial, incrementing primary key ID.
      # However, at the current stage, Hanami will severely complain if your
      # entity does not have a primary key that is named exactly +id+.
      #
      # This column, therefore, does not have any meaning other than letting
      # Hanami happy. Maybe in a future version when they improve this
      # coupling, we might remove this column.
      primary_key :id

      column :key,        String, size: 1024, null: false
      column :value,      String, text: true, null: false
      column :updated_at, Time,               null: false

      # cache keys should be indexed, and unique
      index :key, unique: true
    end
  end
end
